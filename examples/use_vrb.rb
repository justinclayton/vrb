#!/usr/bin/env ruby -I ../lib

require 'vrb'

vc = Vrb::Vcenter.new
dc = vc.get_datacenter 'Tukwila'
cl = dc.get_cluster 'Tukwila Lower'
vm = cl.get_vm 'pxe-test'
vm.change_network('nic1', '969_Build_DHCP')
vm.clone('deleteme59', 'custom-spec-fixed', '10.200.225.250', vc)
