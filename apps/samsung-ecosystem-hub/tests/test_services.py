import os
import tempfile
import unittest
from pathlib import Path

from samsung_hub.services import config
from samsung_hub.services.runner import have, run


class RunnerTests(unittest.TestCase):
    def test_missing_command(self):
        res = run(["definitely-not-a-real-command-xyz"])
        self.assertFalse(res.ok)
        self.assertTrue(res.missing)

    def test_no_shell_interpretation(self):
        res = run(["echo", "$(id); ls"])
        self.assertEqual(res.out.strip(), "$(id); ls")

    def test_timeout(self):
        if not have("sleep"):
            self.skipTest("нет sleep")
        res = run(["sleep", "2"], timeout=0.2)
        self.assertTrue(res.timed_out)


class ConfigTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self._old = os.environ.get("XDG_CONFIG_HOME")
        os.environ["XDG_CONFIG_HOME"] = self.tmp.name

    def tearDown(self):
        if self._old is None:
            os.environ.pop("XDG_CONFIG_HOME", None)
        else:
            os.environ["XDG_CONFIG_HOME"] = self._old
        self.tmp.cleanup()

    def test_defaults_and_roundtrip(self):
        self.assertEqual(config.load()["theme"], "system")
        data = config.load()
        data["theme"] = "dark"
        config.save(data)
        self.assertEqual(config.load()["theme"], "dark")

    def test_invalid_theme_falls_back(self):
        path = config.config_file()
        path.parent.mkdir(parents=True)
        path.write_text('{"theme": "neon"}')
        self.assertEqual(config.load()["theme"], "system")

    def test_autostart_file(self):
        config.set_autostart(True, "/usr/bin/hub")
        self.assertTrue(config.is_autostart())
        self.assertIn("Exec=/usr/bin/hub --background", Path(config.autostart_file()).read_text())
        config.set_autostart(False, "/usr/bin/hub")
        self.assertFalse(config.is_autostart())


if __name__ == "__main__":
    unittest.main()
