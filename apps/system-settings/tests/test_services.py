import json
import unittest

from macsettings.services import hardware, network, system


class NetworkTests(unittest.TestCase):
    def test_split_escaped(self):
        self.assertEqual(network.split_nmcli(r"yes:My\:Net:80:WPA2"), ["yes", "My:Net", "80", "WPA2"])

    def test_wifi_merge_duplicates(self):
        nets = network.parse_wifi_list("no:Home:75:WPA2\nyes:Home:60:WPA2\nno:Cafe:90:\n")
        self.assertEqual(nets[0]["ssid"], "Home")
        self.assertTrue(nets[0]["active"])
        self.assertEqual(nets[0]["signal"], 75)
        self.assertFalse(nets[1]["secure"])

    def test_bluez_only_paired(self):
        d = lambda **kw: {k: {"type": "x", "data": v} for k, v in kw.items()}
        js = json.dumps({"data": [{
            "/org/bluez/hci0": {"org.bluez.Adapter1": d(Powered=True)},
            "/a": {"org.bluez.Device1": d(Address="AA:BB:CC:DD:EE:FF", Alias="Buds", Paired=True, Connected=True),
                   "org.bluez.Battery1": d(Percentage=50)},
            "/b": {"org.bluez.Device1": d(Address="11:22:33:44:55:66", Alias="Stranger", Paired=False)},
        }]})
        powered, devs = network.parse_bluez(js)
        self.assertTrue(powered)
        self.assertEqual([x["name"] for x in devs], ["Buds"])
        self.assertEqual(devs[0]["battery"], 50)

    def test_bt_rejects_bad_address(self):
        self.assertIsNone(network.bt_connect("; reboot", True))


class HardwareTests(unittest.TestCase):
    STATUS = """PipeWire 'pipewire-0' [1.6.10]
Audio
 ├─ Devices:
 │      45. Ryzen HD Audio Controller           [alsa]
 ├─ Sinks:
 │  *   56. Built-in Speakers                   [vol: 0.49]
 │      60. HDMI Output                         [vol: 1.00 MUTED]
 ├─ Sources:
 │  *   57. Internal Microphone                 [vol: 1.00]
 ├─ Filters:
Video
 ├─ Devices:
"""

    def test_wpctl_status(self):
        r = hardware.parse_wpctl_status(self.STATUS)
        self.assertEqual([s["id"] for s in r["sinks"]], [56, 60])
        self.assertTrue(r["sinks"][0]["default"])
        self.assertEqual(r["sinks"][1]["name"], "HDMI Output")
        self.assertEqual(r["sources"][0]["name"], "Internal Microphone")

    def test_volume(self):
        self.assertEqual(hardware.parse_volume("Volume: 0.45 [MUTED]"), (0.45, True))


class SystemTests(unittest.TestCase):
    def test_upower(self):
        text = "  state:               discharging\n  energy-full:  30,1 Wh\n  energy-full-design: 43 Wh\n  percentage:  64%\n  charge-cycles: 206\n"
        b = system.parse_upower(text)
        self.assertEqual(b["percent"], 64)
        self.assertEqual(b["health"], 70)
        self.assertEqual(b["cycles"], 206)

    def test_meminfo_cpu(self):
        self.assertEqual(system.parse_meminfo("MemTotal:  6000000 kB\n"), 6)
        self.assertIn("Ryzen", system.parse_cpu("model name\t: AMD Ryzen 5  3500U\n"))


if __name__ == "__main__":
    unittest.main()
