#!/usr/bin/env ruby -I ../lib

require 'vrb'

vc = Vrb::Vcenter.new
dc = vc.get_datacenter 'Tukwila'
cl = dc.get_cluster 'Tukwila Lower'
vm = cl.get_vm 'pxe-test'
