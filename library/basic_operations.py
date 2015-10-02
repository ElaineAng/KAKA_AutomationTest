__author__ = 'elaine'

import re
import random

from xml.etree.cElementTree import *
from time import *

from library.locate_element import *

# =================================================Helper Functions===================================================
def get_reference_number(order):
    ref_num = ''
    order_details = parse(order)
    order_root = order_details.getroot()
    for details in order_root.iter():
        if details.tag == 'clientReferenceNumber':
            ref_num = details.text
            break
    return ref_num.split('-')[1]


def get_device_id():
    config = yaml.load(open('config.yml', 'r'))
    return config['device_id']


def which_env():
    config = yaml.load(open('config.yml', 'r'))
    env = config['env'].lower()

    if env == "user_defined":
        return {"click": 'env_click',
                "edit": 'env_edit',
                "address": config['env_address']['user_defined']}
    else:
        return 'env_' + env


# =================================================Direct Operations==================================================

# ------------------------------------------------------common--------------------------------------------------------
def compulsory_refresh(driver):
    class_locate(driver, 'image_button').click()  # restrictions: take the menu bar as image_button_class
    xpath_locate(driver, 'compulsorily_refresh').click()
    sleep(5)


def find_order(driver, order=None, order_num=None):  # find order by reference number or by order number
    if order:
        num = get_reference_number(order)
    elif order_num:
        num = order_num

    digit_num = re.findall(r'\d+', num)[0]  # get only digits from order number, avoid keyboard complications
    print('The number for search is', digit_num)
    id_locate(driver, 'magnifier').click()
    id_locate(driver, 'search_text').send_keys(digit_num)
    class_locate(driver, 'relative_layout').click()


def get_progress_details(driver):
    swipe_down(driver)
    pd = id_locate(driver, 'progress_details').text
    return pd


def go_back_to_main(driver):
    xpath_locate(driver, 'truck_logo').click()
    xpath_locate(driver, 'truck_logo_mini').click()


def pull_to_refresh(driver):
    driver.swipe(start_x=550, start_y=370, end_x=550, end_y=1160, duration=1000)
    driver.implicitly_wait(5)


def swipe(driver):
    for i in range(2):
        # for phone that has screen resolution of 1920*1080:
        # driver.swipe(start_x=900, start_y=900, end_x=100, end_y=900, duration=800)

        # for phone that has screen resolution of 1280*720:
        driver.swipe(start_x=650, start_y=500, end_x=50, end_y=500, duration=800)

        driver.implicitly_wait(5)

    id_locate(driver, 'get_started').click()


def swipe_down(driver):
    for i in range(4):
        driver.swipe(start_x=300, start_y=1110, end_x=330, end_y=230, duration=1000)
        sleep(1)


def upload_picture(driver):  # for redmi only
    id_locate(driver, 'upload_photo', multiple=True)[1].click()
    sleep(2)
    driver.tap([(480, 180)], 500)
    sleep(1)
    driver.tap([(200, 780)], 500)
    sleep(1)
    driver.tap([(90, 300)], 500)
    sleep(2)


# ----------------------------------------------------activation------------------------------------------------------
def select_env(driver):
    sleep(3)
    swipe(driver)
    input_phone_number(driver, 11111111111)

    # keyboard existence need checking here; not exist in Redmi
    # driver.hide_keyboard()

    # for phone that has screen resolution of 1920*1080
    # driver.tap([(1050, 80)], 500)
    # driver.tap([(10, 80)], 500)
    # driver.tap([(10, 1760)], 500)

    # for phone that has screen resolution of 1280*720
    driver.tap([(700, 60)], 500)
    driver.tap([(10, 60)], 500)
    driver.tap([(10, 1250)], 500)
    driver.implicitly_wait(5)

    env = which_env()

    if isinstance(env, str):
        id_locate(driver, env).click()
    else:
        id_locate(driver, env['edit']).send_keys(env['address'])
        id_locate(driver, env['click']).click()
        driver.hide_keyboard()

    sleep(3)
    id_locate(driver, 'ok').click()


def input_phone_number(driver, number):
    id_locate(driver, 'phone_number').send_keys(number)


def activate(driver):
    id_locate(driver, 'get_activation_code').click()


# -------------------------------------------------pickup & delivery---------------------------------------------------
def pickup(driver, orders=None, order_num=None):
    order_num = orders.get_pickup_order_list()[0] if not order_num else order_num
    find_order(driver, order_num=order_num)

    id_locate(driver, 'report_pickup').click()
    sleep(3)

    return order_num


def confirm_pickup(driver):
    id_locate(driver, 'Report_Pickup').click()
    sleep(3)


def delivery(driver, orders=None, order_num=None):
    order_num = orders.get_delivery_order_list()[0] if not order_num else order_num
    find_order(driver, order_num=order_num)

    id_locate(driver, 'report_delivery').click()
    sleep(3)

    return order_num


def confirm_delivery(driver):
    id_locate(driver, 'Report_Delivery').click()
    sleep(3)


def batch_pickup(driver):
    class_locate(driver, 'image_button').click()
    xpath_locate(driver, 'batch_pickup').click()
    id_locate(driver, 'ok').click()

    kept_order = []
    total = int(re.findall(r'\d+', id_locate(driver, 'batch_total').text)[0])
    left = random.randint(1, total)
    left = 5 if left > 5 else left
    print('{} orders are going to be batch picked up.'.format(total - left))

    xpath_locate(driver, 'batch_gather')

    for i in range(2, left + 2):
        whole_order = '/android.widget.RelativeLayout[{}]'.format(i)
        order_num = '/android.widget.TextView[4]'
        kept_order_num = xpath_locate(driver, 'orders_in_mark_all', etc0=whole_order, etc1=order_num).text
        xpath_locate(driver, 'orders_in_mark_all', etc0=whole_order).click()
        kept_order.append(kept_order_num)

    id_locate(driver, 'batch_pickup').click()
    sleep(total - left)

    return kept_order


# --------------------------------------------transit event, damage, and lost-----------------------------------------
def register_cargo_damage_and_lost(driver, orders, is_pickup=None, is_delivery=None,
                                   total_lost=None, total_damage=None):
    if not is_pickup and not is_delivery:
        print("Specifying certain order type is required.")
        driver.quit()
        return None
    elif is_pickup is True:
        pickup_orders = orders.get_pickup_order_list()
        order_num = pickup_orders[0]
        print('Cargo damage and lost for pickup:', order_num)
    elif is_delivery is True:
        delivery_orders = orders.get_delivery_order_list()
        order_num = delivery_orders[0]
        print('Cargo damage and lost for delivery:', order_num)

    cargo_quantities = orders.get_cargo_quantities(order_num)
    damage_quantities = random.randint(1, int(cargo_quantities) / 2 - 1)
    lost_quantities = random.randint(1, cargo_quantities / 2 - damage_quantities)
    total_lost += lost_quantities
    total_damage += damage_quantities
    pickup(driver, order_num=order_num) if is_pickup else delivery(driver, order_num=order_num)

    id_locate(driver, 'cargo_damage').click()
    id_locate(driver, 'cargo_lost').click()

    id_locate(driver, 'damage_num').send_keys(damage_quantities)
    id_locate(driver, 'lost_num').send_keys(lost_quantities)
    driver.hide_keyboard()
    id_locate(driver, 'comments').send_keys('well you have a problem..')

    confirm_pickup(driver) if is_pickup else confirm_delivery(driver)
    return total_lost, total_damage


def register_transit_event(driver, orders):
    delivery_orders = orders.get_delivery_order_list()
    order_num = delivery_orders[0]
    print('The order for testing transit event is', order_num)

    find_order(driver, order_num=order_num)
    id_locate(driver, 'transit_event').click()

    sleep(3)
    upload_picture(driver)  # If you are not using Redmi, please comment or edit this function.

    id_locate(driver, 'comments').send_keys('Emergency! Transit event!')
    sleep(3)
    id_locate(driver, 'ok').click()


# ------------------------------------------------------others--------------------------------------------------------

def mark_all_as_read(driver):
    class_locate(driver, 'image_button').click()
    xpath_locate(driver, 'mark_all').click()


def get_order_num(driver):
    # find_order(driver, ref_num=ref_num)
    order_num = id_locate(driver, 'bar_title').text
    print('Order number is', order_num)
    return order_num


# --------------------------------------------------verifications-----------------------------------------------------

def verify_by_finding_element(driver, ele_name, type, multiple=None, should_exist=None, **params):
    if type == 'id':
        element = id_locate(driver, ele_name, multiple=multiple)

    elif type == 'class':
        element = class_locate(driver, ele_name, multiple=multiple)

    elif type == 'xpath':
        element = xpath_locate(driver, ele_name, multiple=multiple, **params)

    if element is not None:
        if element.__class__ == list:
            existence = False if len(element) == 0 else True
    else:
        existence = False

    if should_exist is True:
        assert (existence is True), 'Required element not found, fail.'
    elif should_exist is False:
        assert (existence is False), 'Element should disappear but did not, fail.'
