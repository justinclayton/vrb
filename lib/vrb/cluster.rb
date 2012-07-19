## Vrb::Cluster
## 
## usage:
##   cl.list_hosts
##     => ['host1', 'host2']
##   vm.get_host('host1')
##     => Vrb::Host('host1')
##   vm.list_vms
##     => ['vm1', 'vm2']
##   vm.get_vm('vm1')
##     => Vrb::VM('vm1')
module Vrb
  class Cluster < VrbObject
    
    attr_reader :mob, :parent_mob
        
    def get_host(name)
      mobs = self.list_hosts(return_as_mobs = true)
      host_mob = mobs.find { |mob| mob.name == name } or fail "Sorry!"
      Host.new(@mob, host_mob)
    end
    
    def list_hosts(return_as_mobs = false)
      mobs = @mob.host
      if return_as_mobs == true
        return mobs
      else
        return mobs.collect { |mob| mob.name }
      end
    end
    
    def get_vm(name)
      mobs = self.list_vms(return_as_mobs = true)
      vm_mob = mobs.find { |mob| mob.name == name } or fail "Sorry!"
      VM.new(@mob, vm_mob)
    end
    
    # for some reason, finding vms this at the cluster 
    def list_vms(return_as_mobs = false)
      mobs = @mob.resourcePool.vm + @mob.resourcePool.resourcePool.collect { |rp| rp.vm }.flatten
      if return_as_mobs == true
        return mobs
      else
        return mobs.collect { |mob| mob.name }
      end
    end
  end
end
