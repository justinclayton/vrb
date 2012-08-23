## Vrb::VM
##
## usage:
##   vm.list_nics
##     => {
##          'nic1'=> { :network => 'network1', :is_connected => true  },
##          'nic2'=> { :network => 'network2', :is_connected => false }
##        }
##   vm.change_network('nic1', 'network3')
##     =>
##   vm.tools_status
##     => 'ToolsOk'
##   vm.os
##     => 'CentOS 4/5/6'
##   vm.ip
##     => '10.0.0.1'
##   vm.host
##     => 'host1' # the parent host of the vm
##   vm.is_a_template
##     => false
module Vrb
  class VM < VrbObject

    attr_reader :mob, :tools_status, :os, :ip, :host, :is_a_template, :nics

    def initialize(parent_mob, self_mob)
      @mob = self_mob
      @parent_mob = parent_mob
      @nics = list_nics
      begin
        @tools_status = @mob.guest.toolsStatus
        @os = @mob.summary.guest.guestFullName
        @ip = @mob.guest.ipAddress
        @host = @mob.runtime.host.name
        @is_a_template = @mob.summary.config.template
      rescue
        @os = nil
        @ip = nil
        @host = nil
        @is_a_template = nil
      end

    end

    def change_network(nic_name, new_network_name)

      spec = VIM.VirtualMachineConfigSpec
      dev_change = VIM.VirtualDeviceConfigSpec
      dev_change.operation = 'edit'

      nic = self.nics[nic_name]
      nic_mob = nic[:nic_mob]
      ## find the dvswitch & dvportgroup and set these vars
      # dv_pg_key
      # dv_switch_uuid
      dvpgs = @mob.runtime.host.network.grep(VIM::DistributedVirtualPortgroup)
      new_network = dvpgs.find { |dvpg| dvpg.name == new_network_name } or fail "couldn't find network called #{new_network_name}"
      dv_pg_key = new_network.key
      dv_switch_uuid = new_network.config.distributedVirtualSwitch.summary.uuid

      ## prepare spec
      dev = VIM.VirtualPCNet32
      dev.deviceInfo = VIM.Description
      dev.deviceInfo.label = nic_mob.deviceInfo.label
      dev.deviceInfo.summary = nic_mob.deviceInfo.summary
      dev.backing = VIM.VirtualEthernetCardDistributedVirtualPortBackingInfo
      dev.backing.port = VIM.DistributedVirtualSwitchPortConnection
      dev.backing.port.portgroupKey = dv_pg_key
      dev.backing.port.switchUuid = dv_switch_uuid
      dev.key = nic_mob.key

      dev_change.device = dev

      spec.deviceChange = [dev_change]

      @mob.ReconfigVM_Task(:spec => spec).wait_for_completion
    end

    def clone( dest_vm_name,
               cust_spec_name = nil,
               dest_ip_address = nil,
               vcenter = nil )

      # create empty clone_spec, then populate properties below
      clone_spec = VIM.VirtualMachineCloneSpec
      # power on new vm after clone?
      clone_spec.powerOn = false
      # create new vm as a template?
      clone_spec.template = false
      # set default location for clone_spec
      clone_spec.location = VIM.VirtualMachineRelocateSpec

      if cust_spec_name
        dest_ip_address.nil? and fail "err: customization specified but no IP specified"
        vcenter.nil? and fail "err: vcenter handle required when customization specified"
        # get the actual customization spec object by name from vcenter
        spec_mgr = vcenter.mob.serviceContent.customizationSpecManager
        clone_spec.customization = spec_mgr.GetCustomizationSpec(:name => cust_spec_name).spec or fail "err: couldn't find customization spec #{cust_spec_name}"
        clone_spec.customization.nicSettingMap.first.adapter.ip.ipAddress = dest_ip_address
      end

      # vm = vc.get_vm_by_path('source_vm_path') <-- isn't working, falling back to rbvmomi method
      # vm_mob = vc.mob.searchIndex.FindByInventoryPath(:inventoryPath => source_vm_path)
      @mob.CloneVM_Task(:folder => @mob.parent, :name => dest_vm_name, :spec => clone_spec).wait_for_completion

    end

    private

    def list_nics
      nics = Hash.new
      nic_mobs = @mob.config.hardware.device.select do |n|
        n.deviceInfo.label =~ /Network\ adapter/
      end
      nic_mobs.each do |n|
        # if the nic is on a dvSwitch, we have to go to it to find the name of the port group
        if n.backing.class.to_s =~ /VirtualEthernetCardDistributedVirtualPortBackingInfo/
          pgs = @mob.runtime.host.network.grep(VIM::DistributedVirtualPortgroup)
          network = pgs.find { |p| p.key == n.backing.port.portgroupKey }
          dvswitch = pgs.collect { |p| p.config.distributedVirtualSwitch }
        end

        nic_name = n.deviceInfo.label
        nic_friendly_name = nic_name.sub(/Network\ adapter\s+/, 'nic')

        nics[nic_friendly_name] = {
          :name => nic_name,
          :network_name => network.name,
          :network_mob => network,
          :nic_mob => n,
          :dvswitch => dvswitch,
          :is_connected => n.connectable.connected
        }
        return nics
      end
    end
  end
end
