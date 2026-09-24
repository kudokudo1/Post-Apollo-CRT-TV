#!/usr/bin/env python3
"""
Persistent Sway geometry bridge for the Post-Apollo TV.

V1 geometry model:

    ┌───────────────────────┬──────────┐
    │                       │          │
    │   Kitty / Zellij      │  SIDE    │
    │   screen              │  PANEL   │
    │                       │          │
    ├───────────────────────┘          │
    │      RECEIVER / DVD              │
    └──────────────────────────────────┘

The terminal is the screen rectangle.
The side panel follows its right edge.
The receiver/deck follows its bottom edge.

Whichever TV member is focused becomes the live geometry leader:
  * terminal move/resize -> side + deck follow
  * side move/resize     -> terminal + deck follow
  * deck move/resize     -> terminal + side follow

Like the fast Discord helper, this talks directly to the Sway IPC socket,
samples quickly, and coalesces follower commands so stale positions cannot
build up behind the pointer.
"""

from __future__ import annotations

import argparse
import json
import os
import socket
import struct
import subprocess
import sys
import threading
import time
from typing import Any

MAGIC = b"i3-ipc"
HEADER = struct.Struct("=6sII")

IPC_COMMAND = 0
IPC_GET_TREE = 4

TERMINAL_APP_ID = "post-apollo-terminal"
SIDE_TITLE = "Post-Apollo Side"
DECK_TITLE = "Post-Apollo Deck"

BEZEL_TOP_TITLE = "Post-Apollo Bezel Top"
BEZEL_LEFT_TITLE = "Post-Apollo Bezel Left"
BEZEL_RIGHT_TITLE = "Post-Apollo Bezel Right"
BEZEL_BOTTOM_TITLE = "Post-Apollo Bezel Bottom"

# Screen-chassis thickness. The bezel lives OUTSIDE Kitty's glass and between
# the screen and the SidePanel / ReceiverDeck. Keep this centralized so visual
# proportion can be tuned without changing authority.
BEZEL_THICKNESS = 30


class SwayIPC:
    def __init__(self) -> None:
        self.sock: socket.socket | None = None

    @staticmethod
    def socket_path() -> str:
        path = os.environ.get("SWAYSOCK") or os.environ.get("I3SOCK")
        if path:
            return path

        return subprocess.check_output(
            ["sway", "--get-socketpath"],
            text=True,
        ).strip()

    def connect(self) -> None:
        self.close()
        sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        sock.connect(self.socket_path())
        self.sock = sock

    def close(self) -> None:
        if self.sock is not None:
            try:
                self.sock.close()
            except OSError:
                pass
            self.sock = None

    def _recv_exact(self, count: int) -> bytes:
        if self.sock is None:
            raise ConnectionError("Sway IPC socket is not connected")

        chunks: list[bytes] = []
        remaining = count

        while remaining:
            chunk = self.sock.recv(remaining)
            if not chunk:
                raise ConnectionError("Sway IPC socket closed")
            chunks.append(chunk)
            remaining -= len(chunk)

        return b"".join(chunks)

    def request(self, message_type: int, payload: str = "") -> Any:
        encoded = payload.encode("utf-8")

        for attempt in range(2):
            try:
                if self.sock is None:
                    self.connect()

                assert self.sock is not None
                self.sock.sendall(
                    HEADER.pack(MAGIC, len(encoded), message_type)
                    + encoded
                )

                raw_header = self._recv_exact(HEADER.size)
                magic, length, _response_type = HEADER.unpack(raw_header)

                if magic != MAGIC:
                    raise ConnectionError("Invalid Sway IPC response magic")

                raw_payload = self._recv_exact(length)
                return json.loads(raw_payload.decode("utf-8"))

            except (OSError, ConnectionError, json.JSONDecodeError):
                self.close()
                if attempt == 1:
                    raise
                time.sleep(0.002)

        raise RuntimeError("unreachable")


def walk_tree(node: dict[str, Any]):
    yield node

    for key in ("nodes", "floating_nodes"):
        for child in node.get(key, []) or []:
            yield from walk_tree(child)


def compact_rect(rect: Any) -> dict[str, int] | None:
    if not isinstance(rect, dict):
        return None

    try:
        return {
            "x": int(rect.get("x", 0)),
            "y": int(rect.get("y", 0)),
            "width": max(1, int(rect.get("width", 1))),
            "height": max(1, int(rect.get("height", 1))),
        }
    except (TypeError, ValueError):
        return None


def snapshot_from_tree(tree: dict[str, Any]) -> dict[str, Any]:
    result: dict[str, Any] = {
        "terminal": None,
        "side": None,
        "deck": None,
        "bezel-top": None,
        "bezel-left": None,
        "bezel-right": None,
        "bezel-bottom": None,
    }

    for node in walk_tree(tree):
        rect = compact_rect(node.get("rect"))
        if rect is None:
            continue

        entry = {
            "rect": rect,
            "focused": bool(node.get("focused", False)),
            "visible": bool(node.get("visible", False)),
        }

        app_id = node.get("app_id")
        title = node.get("name")

        if result["terminal"] is None and app_id == TERMINAL_APP_ID:
            result["terminal"] = entry
        elif result["side"] is None and title == SIDE_TITLE:
            result["side"] = entry
        elif result["deck"] is None and title == DECK_TITLE:
            result["deck"] = entry
        elif result["bezel-top"] is None and title == BEZEL_TOP_TITLE:
            result["bezel-top"] = entry
        elif result["bezel-left"] is None and title == BEZEL_LEFT_TITLE:
            result["bezel-left"] = entry
        elif result["bezel-right"] is None and title == BEZEL_RIGHT_TITLE:
            result["bezel-right"] = entry
        elif result["bezel-bottom"] is None and title == BEZEL_BOTTOM_TITLE:
            result["bezel-bottom"] = entry

    return result


def criteria(target: str) -> str:
    if target == "terminal":
        return f'[app_id="{TERMINAL_APP_ID}"]'
    if target == "side":
        return f'[title="{SIDE_TITLE}"]'
    if target == "deck":
        return f'[title="{DECK_TITLE}"]'
    if target == "bezel-top":
        return f'[title="{BEZEL_TOP_TITLE}"]'
    if target == "bezel-left":
        return f'[title="{BEZEL_LEFT_TITLE}"]'
    if target == "bezel-right":
        return f'[title="{BEZEL_RIGHT_TITLE}"]'
    if target == "bezel-bottom":
        return f'[title="{BEZEL_BOTTOM_TITLE}"]'
    raise ValueError(f"Unknown TV target: {target}")


def build_sync_command(message: dict[str, Any]) -> str:
    target = str(message["target"])
    crit = criteria(target)

    x = int(message["x"])
    y = int(message["y"])
    width = max(1, int(message["width"]))
    height = max(1, int(message["height"]))

    commands: list[str] = []

    if bool(message.get("setup", False)):
        commands.append(f"{crit} floating enable")
        commands.append(f"{crit} border none")

    commands.append(
        f"{crit} resize set width {width} px height {height} px"
    )
    commands.append(
        f"{crit} move absolute position {x} px {y} px"
    )

    if bool(message.get("focus", False)):
        commands.append(f"{crit} focus")

    return "; ".join(commands)


class TvBridge:
    def __init__(self, interval_seconds: float) -> None:
        self.interval = max(0.001, interval_seconds)

        self.poll_ipc = SwayIPC()
        self.command_ipc = SwayIPC()

        self.stop_event = threading.Event()
        self.command_event = threading.Event()

        self.command_lock = threading.Lock()
        self.pending_sync: dict[str, dict[str, Any]] = {}

        self.initialized = False

        # Startup admission gate. New bezel toplevels can briefly perturb Sway
        # while they map. During this window we preserve the canonical geometry
        # captured at bootstrap and refuse to treat those transient changes as
        # user intent.
        self.admission_until = 0.0

        # Canonical TV geometry. These values are Kitty's ACTUAL glass/screen
        # rectangle. The bezel grows outward from this rectangle; it must never
        # steal pixels from the screen just because the chassis exists.
        self.screen_x = 0
        self.screen_y = 0
        self.screen_width = 1200
        self.screen_height = 900
        self.side_width = 210
        self.deck_height = 260

    @staticmethod
    def rect_equal(a: dict[str, int] | None, b: dict[str, int]) -> bool:
        return bool(a) and (
            int(a["x"]) == int(b["x"])
            and int(a["y"]) == int(b["y"])
            and int(a["width"]) == int(b["width"])
            and int(a["height"]) == int(b["height"])
        )

    def desired_rects(self) -> dict[str, dict[str, int]]:
        # Kitty is the canonical screen/glass rectangle. The two-layer bezel
        # grows OUTWARD around it. The SidePanel attaches to the outside of the
        # right bezel and the ReceiverDeck attaches to the outside of the
        # bottom bezel.
        #
        #       top bezel
        #   ┌──────────────────────┐┌──── side ────┐
        #   │ ┌──── Kitty ───────┐ ││              │
        # L │ │                  │ ││              │
        #   │ └──────────────────┘ ││              │
        #   └──────────────────────┘└──────────────┘
        #        bottom bezel
        #   ┌──────── receiver / DVD ──────────────┐
        #
        # The bezel is passive. Kitty / Side / Deck may express user intent;
        # bezel surfaces never become geometry authority.
        b = BEZEL_THICKNESS
        framed_width = self.screen_width + (b * 2)
        framed_height = self.screen_height + (b * 2)

        return {
            "terminal": {
                "x": self.screen_x,
                "y": self.screen_y,
                "width": self.screen_width,
                "height": self.screen_height,
            },
            "side": {
                "x": self.screen_x + self.screen_width + b,
                "y": self.screen_y - b,
                "width": self.side_width,
                "height": framed_height,
            },
            "deck": {
                "x": self.screen_x - b,
                "y": self.screen_y + self.screen_height + b,
                "width": framed_width,
                "height": self.deck_height,
            },
            "bezel-top": {
                "x": self.screen_x - b,
                "y": self.screen_y - b,
                "width": framed_width,
                "height": b,
            },
            "bezel-left": {
                "x": self.screen_x - b,
                "y": self.screen_y,
                "width": b,
                "height": self.screen_height,
            },
            "bezel-right": {
                "x": self.screen_x + self.screen_width,
                "y": self.screen_y,
                "width": b,
                "height": self.screen_height,
            },
            "bezel-bottom": {
                "x": self.screen_x - b,
                "y": self.screen_y + self.screen_height,
                "width": framed_width,
                "height": b,
            },
        }

    def queue_sync(
        self,
        target: str,
        rect: dict[str, int],
        *,
        setup: bool = False,
        focus: bool = False,
    ) -> None:
        message = {
            "target": target,
            **rect,
            "setup": setup,
            "focus": focus,
        }

        with self.command_lock:
            previous = self.pending_sync.get(target)

            if previous is not None:
                message["setup"] = bool(
                    message["setup"] or previous.get("setup", False)
                )
                message["focus"] = bool(
                    message["focus"] or previous.get("focus", False)
                )

            # Latest geometry wins. Old follower positions are discarded.
            self.pending_sync[target] = message

        self.command_event.set()

    def bootstrap(self, snapshot: dict[str, Any]) -> bool:
        terminal = snapshot.get("terminal")
        side = snapshot.get("side")
        deck = snapshot.get("deck")

        if not terminal or not side or not deck:
            return False

        tr = terminal["rect"]
        sr = side["rect"]
        dr = deck["rect"]

        # Preserve Kitty's actual tiled rectangle as the canonical glass size.
        # The bezel is added OUTSIDE it; SidePanel and ReceiverDeck are pushed
        # outward to meet the new framed screen instead of Kitty being shrunk.
        self.screen_x = int(tr["x"])
        self.screen_y = int(tr["y"])
        self.screen_width = max(1, int(tr["width"]))
        self.screen_height = max(1, int(tr["height"]))

        self.side_width = max(1, int(sr["width"]))
        self.deck_height = max(1, int(dr["height"]))

        desired = self.desired_rects()

        # While the TV is admitting its new passive bezel surfaces, transient
        # compositor layout changes are not authoritative. Keep pushing the
        # captured canonical layout until the scene is stable.
        if time.monotonic() < self.admission_until:
            for target in (
                "terminal",
                "side",
                "deck",
                "bezel-top",
                "bezel-left",
                "bezel-right",
                "bezel-bottom",
            ):
                node = snapshot.get(target)
                if not node:
                    continue
                current = node.get("rect")
                if not self.rect_equal(current, desired[target]):
                    self.queue_sync(
                        target,
                        desired[target],
                        setup=target.startswith("bezel-"),
                    )
            return

        for target in (
            "terminal",
            "side",
            "deck",
            "bezel-top",
            "bezel-left",
            "bezel-right",
            "bezel-bottom",
        ):
            self.queue_sync(
                target,
                desired[target],
                setup=True,
                focus=(target == "terminal"),
            )

        self.initialized = True
        self.admission_until = time.monotonic() + 0.75

        print(
            "TvGeometry: initialized "
            f"screen={self.screen_width}x{self.screen_height} "
            f"side={self.side_width}px deck={self.deck_height}px",
            file=sys.stderr,
            flush=True,
        )

        return True

    def follow(self, snapshot: dict[str, Any]) -> None:
        terminal = snapshot.get("terminal")
        side = snapshot.get("side")
        deck = snapshot.get("deck")

        # The screen may intentionally disappear during CRT power-off later.
        # Do not destroy/reset the canonical geometry just because Kitty is gone.
        if not side or not deck:
            return

        if not self.initialized:
            if terminal:
                self.bootstrap(snapshot)
            return

        focused = None

        for name in ("terminal", "side", "deck"):
            node = snapshot.get(name)
            if node and node.get("focused", False):
                focused = name
                break

        if focused is None:
            return

        if focused == "terminal" and terminal:
            r = terminal["rect"]

            # Kitty IS the canonical glass. Moving/resizing it directly updates
            # the screen rect; chassis and attached hardware derive from it.
            self.screen_x = int(r["x"])
            self.screen_y = int(r["y"])
            self.screen_width = max(1, int(r["width"]))
            self.screen_height = max(1, int(r["height"]))

        elif focused == "side":
            r = side["rect"]
            b = BEZEL_THICKNESS

            # Side resize controls its own width and the framed screen height.
            self.side_width = max(1, int(r["width"]))
            self.screen_height = max(1, int(r["height"]) - (b * 2))

            # Side position controls the whole TV position. Convert its outer
            # chassis coordinates back to Kitty's canonical glass rectangle.
            self.screen_x = int(r["x"]) - b - self.screen_width
            self.screen_y = int(r["y"]) + b

        elif focused == "deck":
            r = deck["rect"]
            b = BEZEL_THICKNESS

            # Deck resize controls framed screen width and receiver height.
            self.screen_width = max(1, int(r["width"]) - (b * 2))
            self.deck_height = max(1, int(r["height"]))

            # Deck position controls the whole TV position. Convert the framed
            # receiver coordinates back to Kitty's canonical glass rectangle.
            self.screen_x = int(r["x"]) + b
            self.screen_y = int(r["y"]) - b - self.screen_height

        desired = self.desired_rects()

        for target in (
            "terminal",
            "side",
            "deck",
            "bezel-top",
            "bezel-left",
            "bezel-right",
            "bezel-bottom",
        ):
            if target == focused:
                continue

            node = snapshot.get(target)

            # Kitty may be intentionally absent while the TV chassis remains,
            # and bezel surfaces may map a moment after the core TV.
            if not node:
                continue

            current = node.get("rect")

            if not self.rect_equal(current, desired[target]):
                self.queue_sync(
                    target,
                    desired[target],
                    setup=target.startswith("bezel-"),
                )

    def command_loop(self) -> None:
        while not self.stop_event.is_set():
            self.command_event.wait(0.1)
            self.command_event.clear()

            while not self.stop_event.is_set():
                message = None

                with self.command_lock:
                    if self.pending_sync:
                        _, message = self.pending_sync.popitem()

                if message is None:
                    break

                try:
                    self.command_ipc.request(
                        IPC_COMMAND,
                        build_sync_command(message),
                    )
                except Exception as exc:
                    print(
                        f"TvGeometry: Sway command failed: {exc}",
                        file=sys.stderr,
                        flush=True,
                    )
                    time.sleep(0.01)

    def run(self) -> None:
        worker = threading.Thread(
            target=self.command_loop,
            name="tv-geometry-command",
            daemon=True,
        )
        worker.start()

        try:
            while not self.stop_event.is_set():
                try:
                    tree = self.poll_ipc.request(IPC_GET_TREE)
                    snapshot = snapshot_from_tree(tree)
                    self.follow(snapshot)
                except Exception as exc:
                    print(
                        f"TvGeometry: sample failed: {exc}",
                        file=sys.stderr,
                        flush=True,
                    )
                    time.sleep(0.05)

                time.sleep(self.interval)
        finally:
            self.stop_event.set()
            self.command_event.set()
            worker.join(timeout=0.5)
            self.poll_ipc.close()
            self.command_ipc.close()


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Fast Post-Apollo TV geometry follower"
    )
    parser.add_argument(
        "--interval-ms",
        type=float,
        default=8.0,
        help="Geometry sample interval. Default: 8 ms.",
    )
    args = parser.parse_args()

    bridge = TvBridge(max(1.0, args.interval_ms) / 1000.0)

    try:
        bridge.run()
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()

