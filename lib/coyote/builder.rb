module Coyote
  class Builder

		attr_accessor :config, :options, :input_files, :input_classes

		def initialize(options)
			@options = options
			@config = get_config_or_screw_off
			@input_files = []
			@input_classes = []
		end


		def build
			@config['input'].each { |input| add_input input }
			add_requires
			output = Coyote::Output.new "#{@config['output']}"
			send_files_to_output output
			compress_and_save output
		end


		def add_input(input)
			if input.class == Array
				input.each do |input|
					find_and_add_files input
				end
			elsif input.class == String
				find_and_add_files input
			end
		end

		
		def find_and_add_files(input)
			Dir.glob(input).each do |file|
				@input_files.push file
				@input_classes.push file.gsub(/([.](js))/, '').gsub(/(["]|['])/, '').split('/').last
			end
		end

		
		def add_requires
			@input_files.each do |file|
				required = find_requires file
				required.each do |requirement|
					if ! @input_classes.include? requirement
						find_and_add_files "**/#{requirement}.js"
					end
				end				
			end
		end

		# move this into output and run at compile time
		# so the file is only open once
		# this will also make inserting the classes 
		# in the right place easier		
		def find_requires(input_file)
			required = []
			File.open(input_file) do |file|
				file = file.read
				pattern = Regexp.new(/(\/\/.*)(require )(.*)$/)
				matches = file.scan(pattern)
				matches.each do |match|
					required.push match.last.strip.to_s.gsub(/([.](js))/, '').gsub(/(["]|['])/, '').split('/').last
				end
			end
			return required
		end	


		def send_files_to_output(output)
			@input_files.uniq.each do |file|
				output.append file
			end
		end


		def compress_and_save(output)
			if @options[:compress] || @config['compress']
				output.compress
			end

			output.save
		end


		def get_config_or_screw_off
			if File.exists?(Coyote::CONFIG_FILENAME)
				begin
					config = YAML.load(File.open(Coyote::CONFIG_FILENAME))
					if config.class == Hash && ! config.empty?
				  	return config
					else
						print "Coyote configuration exists but has not been defined yet. Configure it in #{Coyote::CONFIG_FILENAME}\n".red
						exit(0)
					end
				rescue ArgumentError => e
				  print "Could not parse YAML: #{e.message}\n".red
				  return false
				end
			else
				print "Could not find a Coyote configuration file in this directory. Use 'coyote generate' to create one.\n".red
				exit
			end
		end



  end
end