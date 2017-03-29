module Nanoc::Int
  # @private
  class ActionProvider
    extend DDPlugin::Plugin

    def self.for(_site)
      raise NotImplementedError
    end

    def rep_names_for(_item)
      raise NotImplementedError
    end

    def memory_for(_rep)
      raise NotImplementedError
    end

    def paths_for(rep)
      # TODO: move to RuleMemory
      memory_for(rep).paths
    end

    def need_preprocessing?
      raise NotImplementedError
    end

    def preprocess(_site)
      raise NotImplementedError
    end

    def postprocess(_site, _reps)
      raise NotImplementedError
    end
  end
end
