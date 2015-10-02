__author__ = 'elaine'

from library.initialize_order import *
from library.basic_operations import *
from library.orders_object import Orders

from time import *
from appium import webdriver

import unittest
import os

class OrderTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.order = init_order(multiple=False)
        cls.device_id = get_device_id()

    @classmethod
    def tearDownClass(cls):
        pass

    def setUp(self):

        desired_caps = {'platformName': 'Android',
                        'platformVersion': '4.4',
                        'deviceName': 'Redmi',
                        'app': os.path.dirname(__file__)+'/../new_driver.apk',
                        'noReset': True,
                        'newCommandTimeout': 60
                        }

        self.driver = webdriver.Remote('http://0.0.0.0:4723/wd/hub', desired_caps)

    def tearDown(self):
        self.driver.quit()

    def test_change_env(self):
        select_env(self.driver)

    def test_login(self):
        # operations
        # swipe(self.driver)
        input_phone_number(self.driver, 13120500388)
        activate(self.driver)
        sleep(10)

        # verification
        verify_by_finding_element(self.driver, ele_name='tab_title', type='id', should_exit=True)

    def test_pickup(self):  # By searching order number
        # operations
        compulsory_refresh(self.driver)

        orders = Orders(self.device_id)
        order_num = pickup(self.driver, orders)
        confirm_pickup(self.driver)

        # verification
        print('The order for testing pickup is', order_num)
        assert (get_progress_details(self.driver) == 'Picked'), 'KAKA progress details did not update.'
        orders.update()
        assert orders.check_milestone(order_num=order_num, expectation=4) is True, 'Pickup verification fails.'

    def test_delivery(self):  # By searching order number
        # operations
        compulsory_refresh(self.driver)

        orders = Orders(self.device_id)
        order_num = delivery(self.driver, orders)
        confirm_delivery(self.driver)

        # verification
        print('The order for testing delivery is', order_num)
        assert (get_progress_details(self.driver) == 'Delivered'), 'KAKA progress details did not update.'
        orders.update()
        assert orders.check_milestone(order_num=order_num, expectation=5) is True, 'Delivery verification fails.'

    def test_batch_pickup(self):
        # operations

        # init_orders(multiple=True)  # Get multiple orders for testing batch pickup
        orders = Orders(self.device_id)
        left_orders = batch_pickup(self.driver)

        # verification
        orders.update()
        pickup_orders = orders.get_pickup_order_list()
        print('Orders that are not picked up by batch pickup:', left_orders)
        print('Orders that are currently in pickup status:', pickup_orders)
        assert (len(left_orders) == len(pickup_orders)), 'Left order quantity is wrong.'
        for i in range(len(left_orders)):
            assert (left_orders[i] in pickup_orders), 'Left order is wrong.'

    def test_transit_event(self):
        # operations
        orders = Orders(self.device_id)
        register_transit_event(self.driver, orders)

        # verification
        print(get_progress_details(self.driver))

    def test_cargo_damage_and_lost(self):
        # operations
        orders = Orders(self.device_id)
        total_lost, total_damage = register_cargo_damage_and_lost(self.driver, orders,
                                                                  is_pickup=True, total_lost=0, total_damage=0)

        # verification
        print('Total lost quantity is', total_lost)
        print('Total damage quantity is', total_damage)

        # operations
        go_back_to_main(self.driver)
        total_lost, total_damage = register_cargo_damage_and_lost(
            self.driver, orders, is_delivery=True, total_lost=0, total_damage=0)

        # verification
        print('Total lost quantity is', total_lost)
        print('Total damage quantity is', total_damage)

        """
            This test case may need to be verified manually. (In system T&T--cargo discrepancy)
            Remember to confirm damage and lost in system before try next time!
            The quantity would be otherwise inaccurate.
        """

    def test_mark_all_as_read(self):
        # operations
        mark_all_as_read(self.driver)

        # verification
        verify_by_finding_element(self.driver, ele_name='new_dot', type='id', multiple=True, should_exist=False)

    def test_upload_epod(self):
        pass

        """
            To be written. The order for verifying uploading e_pod needs to be dispatched from SP to SR.
        """


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(OrderTest)
    unittest.TextTestRunner(verbosity=2).run(suite)
