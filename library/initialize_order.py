__author__ = 'elaine'

from subprocess import Popen, PIPE
from library.basic_operations import *

import os

def change_ref_number(order):
    order_details = parse(order)
    order_root = order_details.getroot()
    label = strftime('%Y%m%d%H%M%S')

    for details in order_root.iter():
        if details.tag == "clientReferenceNumber":
            details.text = 'id-' + label

        if details.tag == "erpNumber":
            details.text = 'erp-' + label

    order_details.write(os.path.dirname(__file__)+'/../import_order.xml', 'UTF-8', xml_declaration=True)


def init_order(multiple):
    print("Importing, releasing, and dispatching from system...")

    order = os.path.dirname(__file__)+"/../import_order.xml"
    change_ref_number(order)
    executions = ['import_order_for_kaka(order, 1)',
                  'release_order_for_kaka(remark:ref(order))',
                  'dispatch_order_for_kaka(remark:ref(order))']
    if multiple:
        executions[0] = 'import_order_for_kaka(order, 6)'

    i = 0
    with Popen(['ruby', os.path.dirname(__file__)+'/../otms_RegTest/bin/interact_with_kaka.rb'],
               stdin=PIPE, stdout=PIPE, bufsize=1, universal_newlines=True) as ruby:

        while i < len(executions):
            line = executions[i]
            i += 1
            print(line, file=ruby.stdin, flush=True)
            result = []
            for out in ruby.stdout:
                out = out.rstrip('\n')
                if out == "[end]":
                    break
                result.append(out)
            else:
                print("Slave has terminated.")
                break
            print("result:" + "\n".join(result))

    return order


if __name__ == '__main__':
    init_order(multiple=False)
