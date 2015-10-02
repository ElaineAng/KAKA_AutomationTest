__author__ = 'elaine'

# from dicttoxml import *

import requests
import json

class Orders:

    # ---------------------------------------------------Constructor---------------------------------------------------

    def __init__(self, device_id):
        self._device_id = device_id
        self._order_list = self._get_order_list()
        self._classified_order_list = self._get_classified_order_list()

    def _get_order_list(self):
        json_order_list = requests.get(self._api_url(type='orderList'), headers=self._header())
        dict_order_list = json.loads(json_order_list.text)
        return dict_order_list['orderList']['newOrders']

    def _api_url(self, type, order_id=None, date=None, state=None):
        url = ''
        if type == 'orderList':
            url = 'http://uat.otms.cn:8080/opentms-webService/ws/driver/v1/orders?page=1'
        elif type == 'orderChange':
            url = 'http://uat.otms.cn:8080/opentms-webService/ws/driver/v1/orders/'+str(date)+'/'+str(state)
        elif type == 'orderDetails':
            url = 'http://uat.otms.cn:8080/opentms-webService/ws/driver/v1/order/'+str(order_id)
        return url

    def _header(self):
        return {'deviceTokenId': self._device_id}

    def _get_classified_order_list(self):
        pickup_orders = []
        delivery_orders = []

        for order in self._order_list:
            milestone = int(order['prevM']['id'].split('_')[1])
            if milestone == 3:
                pickup_orders.append(order['num'])
            elif milestone == 4:
                delivery_orders.append(order['num'])
        return {'pickup': pickup_orders, 'delivery': delivery_orders}

    def _get_order_details(self, order_num):

        # dump(ET.fromstring(str(detail,encoding='utf-8')))
        for order in self._order_list:
            if order['num'] == order_num:
                order_id = order['id']
                break
        json_order_details = requests.get(self._api_url('orderDetails', order_id=order_id), headers=self._header())
        dict_order_details = json.loads(json_order_details.text)
        return dict_order_details

    # ------------------------------------------------Private Methods--------------------------------------------------

    def _get_order_current_milestone(self, order_num):

        for order in self._order_list:
            if order['num'] == order_num:
                order_milestone = order['prevM']['id']
                break

        current_milestone = int(order_milestone.split('_')[1])
        return current_milestone

    # ------------------------------------------------Public Methods---------------------------------------------------
    def check_milestone(self, order_num, expectation):
        current_milestone = self._get_order_current_milestone(order_num)
        return True if current_milestone == expectation else False

    def get_classified_order_list(self):
        return self._classified_order_list

    def get_pickup_order_list(self):
        return self._classified_order_list['pickup']

    def get_delivery_order_list(self):
        return self._classified_order_list['delivery']

    def get_cargo_quantities(self, order_num):
        for order in self._order_list:
            if order['num'] == order_num:
                return order['quantity']

    def get_pickup_order_quantities(self):
        return len(self._classified_order_list['pickup'])

    def get_delivery_order_quantities(self):
        return len(self._classified_order_list['delivery'])

    def update(self, device_id=None):
        if device_id:
            self._device_id = device_id
        self._order_list = self._get_order_list()
        self._classified_order_list = self._get_classified_order_list()


if __name__ == '__main__':

    def check():
        # device_id = 'WWR7V5RJSKUOK4E5QDNF7JZZ'
        orders = Orders(device_id)
        print(orders.check_milestone(device_id, 'nyush000086', 4))

    # check()

