## Vrb::Datacenter
##
## usage:
##   dc.list_clusters
##     => ['cluster1', 'cluster2']
##   dc.get_cluster('cluster1')
##     => Vrb::Cluster('cluster1')
module Vrb
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
end
