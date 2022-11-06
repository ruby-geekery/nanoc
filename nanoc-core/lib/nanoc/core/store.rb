# frozen_string_literal: true

module Nanoc
  module Core
    # An abstract superclass for classes that need to store data to the
    # filesystem, such as checksums, cached compiled content and dependency
    # graphs.
    #
    # Each store has a version number. When attempting to load data from a store
    # that has an incompatible version number, no data will be loaded, but
    # {#version_mismatch_detected} will be called.
    #
    # @abstract Subclasses must implement {#data} and {#data=}, and may
    #   implement {#no_data_found} and {#version_mismatch_detected}.
    #
    # @api private
    class Store
      include Nanoc::Core::ContractsSupport

      # @return [String] The name of the file where data will be loaded from and
      #   stored to.
      attr_reader :filename

      # @return [Numeric] The version number corresponding to the file format
      #   the data is in. When the file format changes, the version number
      #   should be incremented.
      attr_reader :version

      # Creates a new store for the given filename.
      #
      # @param [String] filename The name of the file where data will be loaded
      #   from and stored to.
      #
      # @param [Numeric] version The version number corresponding to the file
      #   format the data is in. When the file format changes, the version
      #   number should be incremented.
      def initialize(filename, version)
        @filename = filename
        @version  = version
      end

      # Logic for building tmp path from active environment and store name
      # @api private
      contract C::KeywordArgs[config: Nanoc::Core::Configuration, store_name: String] => C::AbsolutePathString
      def self.tmp_path_for(store_name:, config:)
        File.absolute_path(
          File.join(tmp_path_prefix(config.output_dir), store_name),
          config.dir,
        )
      end

      contract String => String
      def self.tmp_path_prefix(output_dir)
        dir = Digest::SHA1.hexdigest(output_dir)[0..12]
        File.join('tmp', 'nanoc', dir)
      end

      # @group Loading and storing data

      # @return The data that should be written to the disk
      #
      # @abstract This method must be implemented by the subclass.
      def data
        raise NotImplementedError.new('Nanoc::Core::Store subclasses must implement #data and #data=')
      end

      # @param new_data The data that has been loaded from the disk
      #
      # @abstract This method must be implemented by the subclass.
      #
      # @return [void]
      def data=(new_data) # rubocop:disable Lint/UnusedMethodArgument
        raise NotImplementedError.new('Nanoc::Core::Store subclasses must implement #data and #data=')
      end

      # Loads the data from the filesystem into memory. This method will set the
      #   loaded data using the {#data=} method.
      #
      # @return [void]
      def load
        Nanoc::Core::Instrumentor.call(:store_loaded, self.class) do
          load_uninstrumented
        end
      end

      def load_uninstrumented
        # If there is no database, no point in loading anything
        return unless File.file?(version_filename)

        begin
          # Check if store version is the expected version. If it is not, don’t
          # load.
          read_version = read_obj_from_file(version_filename)
          return if read_version != version

          # Load data
          self.data = read_obj_from_file(data_filename)
        rescue
          # An error occurred! Remove the database and try again
          FileUtils.rm_f(version_filename)
          FileUtils.rm_f(data_filename)

          # Try again
          # TODO: Probably better not to try this indefinitely.
          load_uninstrumented
        end
      end

      # Stores the data contained in memory to the filesystem. This method will
      #   use the {#data} method to fetch the data that should be written.
      #
      # @return [void]
      def store
        # NOTE: Yes, the “store stored” name is a little silly. Maybe stores
        # need to be renamed to databases or so.
        Nanoc::Core::Instrumentor.call(:store_stored, self.class) do
          store_uninstrumented
        end
      end

      def store_uninstrumented
        FileUtils.mkdir_p(File.dirname(filename))

        write_obj_to_file(version_filename, version)
        write_obj_to_file(data_filename, data)

        # Remove old file (back from the PStore days), if there are any.
        FileUtils.rm_f(filename)
      end

      private

      def write_obj_to_file(fn, obj)
        File.binwrite(fn, Marshal.dump(obj))
      end

      def read_obj_from_file(fn)
        Marshal.load(File.binread(fn))
      end

      def version_filename
        "#{filename}.version.db"
      end

      def data_filename
        "#{filename}.data.db"
      end
    end
  end
end
