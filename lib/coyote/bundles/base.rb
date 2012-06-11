require 'coyote/assets'

module Coyote::Bundles
  class Base

    class << self
      def filetypes(*args)
        @filetypes ||= args.map { |arg| arg.to_s.gsub('.','') } || []
      end
    end
    
    filetypes :js, :coffee, :css, :less

    attr_accessor :contents
    attr_reader :assets, :target
    
    def initialize(target)
      @target = target
      empty!
    end

    def add(input)
      path = File.expand_path(input)
      if File.directory? path
        add_directory path
      elsif File.exists? path
        add_file path
      else
        notify "Could not find #{path}", :failure
      end
    end
    
    
    def add_file(path)
      return false unless path_is_directory_or_kosher_file?(path)
      asset = Coyote::Asset.new(path)
      @assets.delete(path)
      @assets[path] = asset
      add_dependencies(asset)
    end


    def add_directory(dir_path)
      Dir.foreach(dir_path) do |path|
        next if path == '.' or path == '..'
        path = "#{dir_path}/#{path}"
        add path if path_is_directory_or_kosher_file?(path)
      end
    end


    def add_dependencies(asset)
      asset.dependencies.each do |dependency_path|
        relative_directory = File.dirname asset.relative_path
        add File.join relative_directory, dependency_path
      end
    end
    

    def path_is_directory_or_kosher_file?(path)
      return true if File.directory?(path)        
      self.class.filetypes.include? File.extname(path).gsub('.','')
    end


    def empty!
      @assets = {}
    end

  
    def files
      @assets.keys
    end


    def contents
      @contents ||= files.reverse.map { |path| @assets[path].contents }.join
    end
  
  
    def update!(changed_files=[])
      reset!
      changed_files.each { |path| @assets[path].update! }
    end
  
  
    def manifest
      files.reverse.map { |path| "+ #{path}" }.join("\n")
    end
  
  
    def reset!
      @contents = nil      
    end
    
    
    def save!
      File.open target, 'w+' do |file|
        file.write contents
      end      
    end
    

    def compress!
      self
    end
    

  end
end