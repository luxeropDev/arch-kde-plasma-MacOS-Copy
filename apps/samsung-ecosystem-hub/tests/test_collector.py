import unittest

from samsung_hub.models.device import AdbDevice, BtDevice, KcDevice, LinkState
from samsung_hub.services import collector


class PhoneTests(unittest.TestCase):
    def test_connected_with_battery(self):
        kc = [KcDevice("a1b2c3d4e5f6", "Galaxy S24", True, True, 55, False)]
        s = collector.build_phone(True, kc, False, [])
        self.assertEqual(s.state, LinkState.CONNECTED)
        self.assertEqual(s.battery, 55)
        self.assertEqual(s.details["kdeconnectId"], "a1b2c3d4e5f6")

    def test_unpaired_is_not_connected(self):
        kc = [KcDevice("a1b2c3d4e5f6", "Galaxy S24", False, True)]
        s = collector.build_phone(True, kc, False, [])
        self.assertEqual(s.state, LinkState.AVAILABLE)
        self.assertIsNone(s.battery)

    def test_nothing_installed(self):
        s = collector.build_phone(False, [], False, [])
        self.assertEqual(s.state, LinkState.UNAVAILABLE)
        self.assertIn("kdeconnect", s.message)

    def test_adb_fallback_battery(self):
        adb = [AdbDevice("R5CT", "device", "SM S918B", 40)]
        s = collector.build_phone(False, [], True, adb)
        self.assertEqual(s.state, LinkState.CONNECTED)
        self.assertEqual(s.battery, 40)

    def test_unauthorized_adb_ignored(self):
        s = collector.build_phone(False, [], True, [AdbDevice("R5CT", "unauthorized")])
        self.assertEqual(s.state, LinkState.UNAVAILABLE)


class BudsWatchTests(unittest.TestCase):
    def test_buds_connected_no_battery_is_honest(self):
        dev = BtDevice("/p", "AA:BB:CC:DD:EE:01", "Galaxy Buds2", paired=True, connected=True)
        s = collector.build_buds(True, [dev])
        self.assertEqual(s.state, LinkState.CONNECTED)
        self.assertIsNone(s.battery)

    def test_buds_bluetooth_off(self):
        s = collector.build_buds(False, [])
        self.assertEqual(s.state, LinkState.UNAVAILABLE)
        self.assertIn("выключен", s.message)

    def test_watch_via_phone_by_default(self):
        phone = collector.build_phone(False, [], False, [])
        w = collector.build_watch(phone, True, [])
        self.assertEqual(w.state, LinkState.VIA_PHONE)
        self.assertIsNone(w.battery)

    def test_to_qml_marks_missing_battery(self):
        d = collector.build_buds(True, []).to_qml()
        self.assertEqual(d["battery"], -1)
        self.assertFalse(d["hasBattery"])

    def test_pick_prefers_paired_and_reachable(self):
        a = KcDevice("a" * 12, "A", True, False)
        b = KcDevice("b" * 12, "B", True, True)
        self.assertEqual(collector._pick_kc([a, b]).name, "B")


if __name__ == "__main__":
    unittest.main()
