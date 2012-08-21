## Vrb::Host
##
## usage:
##   vm.list_vms
##     => ['vm1', 'vm2']
##   vm.get_vm('vm1')
##     => Vrb::VM('vm1')
module Vrb
  class Host < VrbObject

    attr_reader :mob, :parent_mob

    def get_vm(name)
      VM.new(@mob, name) or fail "Sorry!"
    end

    def list_vms
      mobs = @mob.vm
      mobs.collect { |mob| mob.name }
    end
  end
end
