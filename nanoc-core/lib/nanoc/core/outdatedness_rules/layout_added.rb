# frozen_string_literal: true

module Nanoc
  module Core
    module OutdatednessRules
      class LayoutAdded < Nanoc::Core::OutdatednessRule
        affects_props :raw_content

        contract Nanoc::Core::Layout, C::Named['Nanoc::Core::OutdatednessChecker'] => C::Maybe[Nanoc::Core::OutdatednessReasons::Generic]
        def apply(obj, outdatedness_checker)
          if outdatedness_checker.dependency_store.new_layouts.include?(obj)
            Nanoc::Core::OutdatednessReasons::DocumentAdded
          end
        end
      end
    end
  end
end
