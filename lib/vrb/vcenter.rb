 module Vrb 

  require 'yaml'

  VIM = RbVmomi::VIM
  VCENTER_CONFIG_FILE = '~/.fog'
  
  parse_config_file(VCENTER_CONFIG_FILE)

  def parse_config_file(config_file)
    file = File.open(File.expand_path(VCENTER_CONFIG_FILE)).read
    config = YAML.load(file)[:default]
    vcenter_server = config[:vsphere_server]
    vcenter_username = config[:vsphere_username]
    vcenter_password = config[:vsphere_password]
  end


  class Vcenter

    attr_reader :mob
    
    def initialize( host     = vcenter_server,
                    user     = vcenter_username,
                    password = vcenter_password )
      @mob = VIM.connect  :host     => host,
                          :user     => user,
                          :password => password,
                          :insecure => true
    end
    
    def inspect
      return "#{self.class}(#{@mob.host})"
    end
  
    def get_vm_by_path(path)
      vm_mob = @mob.searchIndex.FindByInventoryPath(:inventoryPath => path)
      VM.new(@mob, vm_mob)
    end
  
    def get_host(name)
      puts "Not implemented yet"
    end
  
    def get_datacenter(name)
      dc_mob = @mob.serviceInstance.find_datacenter(name) or fail "Sorry!"
      Datacenter.new(@mob, dc_mob)
    end
    
    def list_datacenters
      mobs = @mob.rootFolder.children.grep(VIM::Datacenter)
      mobs.collect { |mob| mob.name }
    end
  end
end
