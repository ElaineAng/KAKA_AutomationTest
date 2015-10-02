__author__ = 'elaine'

import unittest

from run_test import HTMLTestRunner
from test_suite.order_tab import OrderTest


def run():
    suite = unittest.TestSuite()
    # suite.addTest(OrderTest("test_change_env"))
    # suite.addTest(OrderTest("test_login"))
    suite.addTest(OrderTest("test_pickup"))
    suite.addTest(OrderTest("test_delivery"))
    suite.addTest(OrderTest("test_batch_pickup"))
    suite.addTest(OrderTest("test_transit_event"))
    suite.addTest(OrderTest("test_cargo_damage_and_lost"))
    suite.addTest(OrderTest("test_mark_all_as_read"))

    filename = "test_for_kaka_result.html"
    fp = open(filename, 'wb')
    runner = HTMLTestRunner.HTMLTestRunner(stream=fp, title="Result", description="TestReport")
    runner.run(suite)
