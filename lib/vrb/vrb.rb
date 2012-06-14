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
    end
  
    def get_host(name)
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

  class Datacenter
    
    attr_reader :mob
    
    def initialize(parent_mob, self_mob)
      @mob = self_mob
    end
        
    def inspect
      return "#{self.class}(#{@mob.name})"
    end
        
    def get_cluster(name)
      Cluster.new(@mob, name) or fail "Sorry!"
    end
    
    def list_clusters
      mobs = @mob.hostFolder.children.grep(VIM::ClusterComputeResource)
      mobs.collect { |cluster_mob| cluster_mob.name }
    end
  end


  class Cluster
    
    def initialize(parent_mob, name)
      mobs = parent_mob.hostFolder.children.grep(VIM::ClusterComputeResource)
      @mob = mobs.find { |mob| mob.name == name }
    end
        
    def inspect
      return "#{self.class}(#{@mob.name})"
    end
    
    def get_host(name)
      Host.new(@mob, name) or fail "Sorry!"
    end
    
    def list_hosts
      mobs = @mob.host
      mobs.collect { |mob| mob.name }
    end
    
    def get_vm(name)
      VM.new(@mob, name) or fail "Sorry!"
    end
    
    def list_vms
      mobs = @mob.resourcePool.vm + @mob.resourcePool.resourcePool.collect { |rp| rp.vm }.flatten
      mobs.collect { |mob| mob.name }
    end
    
  end
  
  class Host
    
    def initialize(parent_mob, name)
      mobs = parent_mob.host
      @mob = mobs.find { |mob| mob.name == name }
    end
        
    def inspect
      return "#{self.class}(#{@mob.name})"
    end
    
    def get_vm(name)
      VM.new(@mob, name) or fail "Sorry!"
    end
    
    def list_vms
      mobs = @mob.vm
      mobs.collect { |mob| mob.name }
    end
  end
  
  class VM
    
    attr_reader :mob, :os, :ip, :tools_status, :host
    
    def initialize(parent_mob, name)
      mobs = case parent_mob.class.to_s
        when "HostSystem"
          parent_mob.vm
        when "ClusterComputeResource"
          parent_mob.resourcePool.vm + parent_mob.resourcePool.resourcePool.collect { |rp| rp.vm }.flatten
      end
      @mob = mobs.find { |mob| mob.name == name }
      
      @os = @mob.summary.guest.guestFullName
      @ip = @mob.guest.ipAddress
      @tools_status = @mob.guest.toolsStatus
      @host = @mob.runtime.host.name
    end
    
    def inspect
      return "#{self.class}(#{@mob.name})"
    end
    
  end
  
end
