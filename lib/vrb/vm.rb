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
    
    attr_reader :mob, :tools_status, :os, :ip, :host, :is_a_template
    
    def initialize(parent_mob, self_mob)
      @mob = self_mob
      @parent_mob = parent_mob
      begin
        @tools_status = @mob.guest.toolsStatus  
        @os = @mob.summary.guest.guestFullName
        @ip = @mob.guest.ipAddress
        @host = @mob.runtime.host.name
        @is_a_template = @mob.summary.config.template
      rescue Exception => e
        @os = nil
        @ip = nil
        @host = nil
        @is_a_template = nil
      end
  
    end

    def list_nics
      puts "Not implemented yet"
      # mobs = @mob.????.findvnicmobs
      # mobs.collect { |mob| mob.????.friendlyname }
    end

    def change_network(nic, new_network)
      puts "Not implemented yet"
    end
  end
end
