module Vrb
  
  require 'rbvmomi'
  require 'fileutils'
  require 'yaml'
  
  VIM = RbVmomi::VIM
  
  VCENTER_CONFIG_FILE = '~/.fog'
  file = File.open(File.expand_path(VCENTER_CONFIG_FILE)).read
  config = YAML.load(file)[:default]
  VCENTER_SERVER = config[:vsphere_server]
  VCENTER_USERNAME = config[:vsphere_username]
  VCENTER_PASSWORD = config[:vsphere_password]

  class VrbObject
    def initialize(parent_mob, self_mob)
      @mob = self_mob
      @parent_mob = parent_mob
    end
    
    def inspect
      return "#{self.class}(#{@mob.name})"
    end
  end
  
  class Vcenter

    attr_reader :mob
    
    def initialize(host = VCENTER_SERVER, user = VCENTER_USERNAME, password = VCENTER_PASSWORD)
      @mob = VIM.connect  host: host,
                          user: user,
                          password: password,
                          insecure: true
    end
    
    def inspect
      return "#{self.class}(#{@mob.host})"
    end
  
    def get_vm(name)
      puts "Not implemented yet"
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

  class Datacenter < VrbObject
    
    attr_reader :mob, :parent_mob
        
    def get_cluster(name)
      mobs = self.list_clusters(return_as_mobs = true)
      cl_mob = mobs.find { |mob| mob.name == name } or fail "Sorry!"
      Cluster.new(@mob, cl_mob)
    end
    
    def list_clusters(return_as_mobs = false)
      mobs = @mob.hostFolder.children.grep(VIM::ClusterComputeResource)
      if return_as_mobs == true
        return mobs
      else
        return mobs.collect { |mob| mob.name }
      end
    end
    
  end


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
  
  class VM < VrbObject
    
    attr_reader :mob, :os, :ip, :tools_status, :host, :is_a_template
    
    def initialize(parent_mob, self_mob)
      @mob = self_mob
      @parent_mob = parent_mob
            
      @os = @mob.summary.guest.guestFullName
      @ip = @mob.guest.ipAddress
      @tools_status = @mob.guest.toolsStatus
      @host = @mob.runtime.host.name
      @is_a_template = @mob.summary.config.template
    end
        
  end
  
end
