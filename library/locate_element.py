__author__ = 'elaine'

import yaml
import os

global page_objects
page_objects = os.path.dirname(__file__)+'/../objects/page_objects.yml'


def load_object(file):
    f = yaml.load(open(file, 'r'))
    return f


def id_locate(driver, name, multiple=None):
    po = load_object(page_objects)
    path = po['resource_id'][name]
    if not multiple:
        return driver.find_element_by_id(path)
    else:
        return driver.find_elements_by_id(path)


def class_locate(driver, name, multiple=None):
    po = load_object(page_objects)
    path = po['class_name'][name]
    if not multiple:
        return driver.find_element_by_class_name(path)
    else:
        return driver.find_elements_by_class_name(path)


def xpath_locate(driver, name, multiple=None, **params):
    po = load_object(page_objects)
    path = po['xpath'][name]
    if params:
        for i in range(len(params)):
            path += params['etc' + str(i)]
    if not multiple:
        return driver.find_element_by_xpath(path)
    else:
        return driver.find_elements_by_xpath(path)
