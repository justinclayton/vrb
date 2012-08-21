#!/usr/bin/env ruby -I ../lib

require 'vrb'
# require 'rbvmomi'
require 'trollop'

opts = Trollop.options do
  banner <<-EOS
  Clone a VM.

  Usage:
      clone_vm.rb source_vm_path dest_vm_name [cust_spec_name] [dest_ip_address] [network_label]

  Example:
      clone_vm.rb Tukwila/vm/UnixTeam/Templates/centos6-test-2 seapnewbox01 custom-test-fixed

  EOS
end

# assign CLI arguments
ARGV.size >= 2 or abort "must specify VM source name and VM target name"
source_vm_path = ARGV[0]
dest_vm_name   = ARGV[1]
if ARGV[2]
  cust_spec_name  = ARGV[2]
  dest_ip_address = ARGV[3] or abort "must specify IP address when using customization"
  if ARGV[4]
    network_label = ARGV[4]
  end
end

# connect to vcenter using .fog file
vc = Vrb::Vcenter.new

# create empty clone_spec, then populate properties below
clone_spec = RbVmomi::VIM.VirtualMachineCloneSpec
# power on new vm after clone?
clone_spec.powerOn = false
# create new vm as a template?
clone_spec.template = false
# set default location for clone_spec
clone_spec.location = RbVmomi::VIM.VirtualMachineRelocateSpec

if cust_spec_name
  # get the actual customization spec object by name from vcenter
  spec_mgr = vc.mob.serviceContent.customizationSpecManager
  clone_spec.customization = spec_mgr.GetCustomizationSpec(:name => cust_spec_name).spec
  clone_spec.customization.nicSettingMap.first.adapter.ip.ipAddress = dest_ip_address
end

# vm = vc.get_vm_by_path('source_vm_path') <-- isn't working, falling back to rbvmomi method
vm_mob = vc.mob.searchIndex.FindByInventoryPath(:inventoryPath => source_vm_path)

vm_mob.CloneVM_Task(:folder => vm_mob.parent, :name => dest_vm_name, :spec => clone_spec).wait_for_completion
