"""Сведения о компьютере, батарее и накопителе — только чтение."""

from __future__ import annotations

import os
import platform
import pwd
import re
import shutil
from pathlib import Path

from ..runner import have, run


def parse_os_release(text: str) -> str:
    m = re.search(r'^PRETTY_NAME="?([^"\n]+)"?', text, re.M)
    return m.group(1) if m else "Linux"


def parse_meminfo(text: str) -> int:
    """Объём памяти в ГБ (округлённо)."""
    m = re.search(r"^MemTotal:\s+(\d+)\s+kB", text, re.M)
    return round(int(m.group(1)) / 1024 / 1024) if m else 0


def parse_cpu(text: str) -> str:
    m = re.search(r"^model name\s*:\s*(.+)$", text, re.M)
    return re.sub(r"\s+", " ", m.group(1)).strip() if m else platform.processor() or "?"


def parse_upower(text: str) -> dict:
    """Разбирает `upower -i <battery>`."""
    def num(key):
        m = re.search(rf"^\s*{key}:\s*([\d.,]+)", text, re.M)
        return float(m.group(1).replace(",", ".")) if m else None

    state = re.search(r"^\s*state:\s*(\S+)", text, re.M)
    pct = num("percentage")
    full, design = num("energy-full"), num("energy-full-design")
    cycles = re.search(r"^\s*charge-cycles:\s*(\d+)", text, re.M)
    health = round(full / design * 100) if full and design else None
    return {
        "present": pct is not None,
        "percent": int(pct) if pct is not None else -1,
        "state": state.group(1) if state else "",
        "health": health if health is not None else -1,
        "cycles": int(cycles.group(1)) if cycles else -1,
    }


def user_info() -> dict:
    pw = pwd.getpwuid(os.getuid())
    full = pw.pw_gecos.split(",")[0].strip() or pw.pw_name
    avatar = ""
    for candidate in (Path.home() / ".face.icon", Path.home() / ".face",
                      Path("/var/lib/AccountsService/icons") / pw.pw_name):
        try:
            if candidate.is_file():
                avatar = str(candidate)
                break
        except OSError:
            pass
    return {"name": full, "login": pw.pw_name, "avatar": avatar}


def about() -> dict:
    def read(path):
        try:
            return Path(path).read_text(errors="replace")
        except OSError:
            return ""

    gpu = ""
    if have("lspci"):
        res = run(["lspci"], timeout=4)
        for line in res.out.splitlines():
            if re.search(r"VGA|3D controller|Display controller", line):
                gpu = line.split(":", 2)[-1].strip()
                gpu = re.sub(r"\s*\(rev [0-9a-f]+\)$", "", gpu)
                break
    product = read("/sys/class/dmi/id/product_name").strip()
    vendor = read("/sys/class/dmi/id/sys_vendor").strip()
    plasma = run(["plasmashell", "--version"], timeout=4).out.strip().replace("plasmashell ", "")
    du = shutil.disk_usage("/")
    return {
        "model": pretty_model(vendor, product) or platform.node(),
        "hostname": platform.node(),
        "os": parse_os_release(read("/etc/os-release")),
        "kernel": platform.release(),
        "plasma": plasma,
        "cpu": parse_cpu(read("/proc/cpuinfo")),
        "memory": parse_meminfo(read("/proc/meminfo")),
        "gpu": gpu,
        "diskTotal": round(du.total / 1e9),
        "diskUsed": round(du.used / 1e9),
        "diskFree": round(du.free / 1e9),
    }


def pretty_model(vendor: str, product: str) -> str:
    """«ASUSTeK COMPUTER INC.» + «ZenBook UX431DA_UM431DA» → «ASUS ZenBook UX431DA»."""
    vendor = {"ASUSTeK COMPUTER INC.": "ASUS", "LENOVO": "Lenovo", "HP": "HP", "Dell Inc.": "Dell"}.get(vendor, vendor)
    product = product.split("_")[0].strip()
    if product.lower().startswith(vendor.lower()):
        return product
    return " ".join(x for x in (vendor, product) if x)


def battery() -> dict:
    if not have("upower"):
        return {"present": False}
    devices = run(["upower", "-e"], timeout=4).out.split()
    bat = next((d for d in devices if "battery_BAT" in d), "")
    if not bat:
        return {"present": False}
    info = parse_upower(run(["upower", "-i", bat], timeout=4).out)
    if have("powerprofilesctl"):
        res = run(["powerprofilesctl", "get"], timeout=4)
        info["profile"] = res.out.strip() if res.ok else ""
        lst = run(["powerprofilesctl", "list"], timeout=4)
        info["profiles"] = re.findall(r"^\*?\s*([\w-]+):\s*$", lst.out, re.M) if lst.ok else []
    return info


def set_power_profile(name: str):
    if name not in ("power-saver", "balanced", "performance"):
        return None
    return run(["powerprofilesctl", "set", name], timeout=6)
