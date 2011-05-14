module Anisoptera
  
  class Commander

    def initialize(base_path)
      @base_path = base_path
      @original = nil
      @geometry = nil
    end

    def file(path)
      @original = path
      self
    end

    def resize(geometry)
      @geometry = geometry
      self
    end
    
    def crop(geometry)
      @crop = geometry
      self
    end
    
    def encode(format)
      @encode = format
      self
    end
    
    def greyscale
      @greyscale = true
      self
    end

    def mime_type
      'image/jpg'
    end
    
    def to_file(path)
      File.open(path, 'w+') do |f|
        f.write(`#{command}`)
      end
    end

    def command
      raise ArgumentError, "no original file provided. Do commander.file('some_file.jpg')" unless @original
      cmd = "convert #{File.join(@base_path, @original)}"
      cmd << " -resize #{@geometry}" if @geometry
      cmd << " -crop #{@crop}" if @crop
      cmd << " -colorspace Gray" if @greyscale
      if @encode
        cmd << " #{@encode}:-" # to stdout
      else
        cmd << ' -'
      end
      cmd
    end

  end
  
end