from qiime2.plugin.testing import TestPluginBase


class TestUsageExamples(TestPluginBase):
    package = "q2_periobiome.tests"

    def test_examples(self):
        self.execute_examples()

    def test_every_action_has_an_example(self):
        for name, action in self.plugin.actions.items():
            self.assertTrue(action.examples, name)
