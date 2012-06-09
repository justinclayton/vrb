module Vrb
  
  require 'rbvmomi'
  VIM = RbVmomi::VIM

  class Vcenter
    
    def initialize(host, user, password)
      @mob = VIM.connect  host: host,
                          user: user,
                          password: password,
                          insecure: true
    end

    def inspect
      return "#{self.class}(#{@mob.host})"
    end
  
    def get_datacenter(name)
      Datacenter.new(@mob, name) or fail "Sorry!"
    end
    
    def list_datacenters
      mobs = @mob.rootFolder.children.grep(VIM::Datacenter)
      mobs.collect { |mob| mob.name }
    end
  end

  class Datacenter
    
    def initialize(parent_mob, name)
      @mob = parent_mob.serviceInstance.find_datacenter(name)
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
    def initialize(parent_mob, name)
      mobs = case parent_mob.class.to_s
        when "HostSystem" then parent_mob.vm
        when "ClusterComputeResource" then parent_mob.resourcePool.vm
      end
      @mob = mobs.find { |mob| mob.name == name }
    end
    
    def inspect
      return "#{self.class}(#{@mob.name})"
    end
    
  end
  
end
