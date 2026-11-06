import json
import unittest

from samsung_hub.integrations import adb, bluez, kdeconnect
from samsung_hub.services.logger import redact


def _bt(props):
    return {k: {"type": "x", "data": v} for k, v in props.items()}


BLUEZ_JSON = json.dumps({"type": "a{oa{sa{sv}}}", "data": [{
    "/org/bluez/hci0": {"org.bluez.Adapter1": _bt({"Powered": True})},
    "/org/bluez/hci0/dev_AA": {
        "org.bluez.Device1": _bt({"Address": "AA:BB:CC:DD:EE:01", "Alias": "Galaxy Buds2 Pro (1234)",
                                  "Paired": True, "Connected": True, "Trusted": True}),
        "org.bluez.Battery1": _bt({"Percentage": 77}),
    },
    "/org/bluez/hci0/dev_BB": {
        "org.bluez.Device1": _bt({"Address": "AA:BB:CC:DD:EE:02", "Alias": "Galaxy Watch6",
                                  "Paired": True, "Connected": False}),
    },
}]})


class BluezTests(unittest.TestCase):
    def test_parse(self):
        powered, devices = bluez.parse_managed_objects(BLUEZ_JSON)
        self.assertTrue(powered)
        self.assertEqual(len(devices), 2)
        buds = devices[0]
        self.assertTrue(buds.connected)
        self.assertEqual(buds.battery, 77)
        self.assertIsNone(devices[1].battery)

    def test_parse_garbage(self):
        self.assertEqual(bluez.parse_managed_objects("not json"), (None, []))
        self.assertEqual(bluez.parse_managed_objects("{}"), (None, []))

    def test_classify(self):
        self.assertEqual(bluez.classify("Galaxy Buds2 Pro (1234)"), "buds")
        self.assertEqual(bluez.classify("Galaxy Buds FE"), "buds")
        self.assertEqual(bluez.classify("Galaxy Watch6 Classic"), "watch")
        self.assertEqual(bluez.classify("JBL Flip 5"), "other")


class KdeConnectTests(unittest.TestCase):
    def test_parse_list(self):
        text = ("2 devices found\n"
                "- Galaxy S24: a1b2c3d4e5f6a7b8 (paired and reachable)\n"
                "- Old tablet: 0123456789abcdef (paired)\n"
                "- Stranger: ffffffffffffffff (reachable)\n")
        devs = kdeconnect.parse_list(text)
        self.assertEqual([d.name for d in devs], ["Galaxy S24", "Old tablet", "Stranger"])
        self.assertEqual([(d.paired, d.reachable) for d in devs], [(True, True), (True, False), (False, True)])

    def test_parse_list_new_format_with_address(self):
        line = "- Galaxy A57 5G: 0f3c9a7e21b84d6a9c5e4f1b2d3a4c5e on 192.168.1.50 via LAN (paired and reachable)"
        devs = kdeconnect.parse_list(line + "\n1 device found\n")
        self.assertEqual(len(devs), 1)
        self.assertEqual(devs[0].name, "Galaxy A57 5G")
        self.assertEqual(devs[0].device_id, "0f3c9a7e21b84d6a9c5e4f1b2d3a4c5e")
        self.assertTrue(devs[0].paired and devs[0].reachable)

    def test_valid_id(self):
        self.assertTrue(kdeconnect.valid_id("a1b2c3d4e5f6a7b8"))
        self.assertFalse(kdeconnect.valid_id("x; rm -rf ~"))
        self.assertFalse(kdeconnect.valid_id(""))

    def test_busctl_value(self):
        self.assertEqual(kdeconnect.parse_busctl_value('{"type":"i","data":85}'), 85)
        self.assertIsNone(kdeconnect.parse_busctl_value("oops"))


class AdbTests(unittest.TestCase):
    def test_parse_devices(self):
        text = ("List of devices attached\n"
                "R5CT12345 device usb:1-1 product:x model:SM_S918B device:dm3q transport_id:1\n"
                "emulator-5554 unauthorized\n")
        devs = adb.parse_devices(text)
        self.assertEqual(len(devs), 2)
        self.assertTrue(devs[0].authorized)
        self.assertEqual(devs[0].model, "SM S918B")
        self.assertFalse(devs[1].authorized)

    def test_battery(self):
        self.assertEqual(adb.parse_battery("Current Battery Service state:\n  level: 64\n  scale: 100\n"), 64)
        self.assertIsNone(adb.parse_battery("nothing"))

    def test_serial_validation(self):
        self.assertTrue(adb.valid_serial("R5CT12345"))
        self.assertTrue(adb.valid_serial("192.168.1.5:5555"))
        self.assertFalse(adb.valid_serial("a b"))
        self.assertFalse(adb.valid_serial("$(id)"))


class RedactTests(unittest.TestCase):
    def test_mac_and_id(self):
        out = redact("connect AA:BB:CC:DD:EE:F9 id a1b2c3d4e5f6a7b8c9")
        self.assertNotIn("AA:BB:CC:DD", out)
        self.assertIn("a1b2c3…", out)
        self.assertNotIn("a1b2c3d4e5f6a7b8c9", out)
        self.assertIn("XX:XX:XX:XX:XX:F9", out)


if __name__ == "__main__":
    unittest.main()
