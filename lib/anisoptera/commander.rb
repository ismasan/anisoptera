module Anisoptera
  
  # Simple interface to ImageMagick main commands
  # Most of it borrowed from DragonFly
  # https://github.com/markevans/dragonfly/blob/master/lib/dragonfly/image_magick/processor.rb
  #
  class Commander
    
    GRAVITIES = {
      'nw' => 'NorthWest',
      'n'  => 'North',
      'ne' => 'NorthEast',
      'w'  => 'West',
      'c'  => 'Center',
      'e'  => 'East',
      'sw' => 'SouthWest',
      's'  => 'South',
      'se' => 'SouthEast'
    }
    
    # Geometry string patterns
    RESIZE_GEOMETRY         = /^\d*x\d*[><%^!]?$|^\d+@$/ # e.g. '300x200!'
    CROPPED_RESIZE_GEOMETRY = /^(\d+)x(\d+)[#|-](\w{1,2})?$/ # e.g. '20x50#ne'
    CROP_GEOMETRY           = /^(\d+)x(\d+)([+-]\d+)?([+-]\d+)?(\w{1,2})?$/ # e.g. '30x30+10+10'
    
    def initialize(base_path)
      @base_path = base_path
      @original = nil
      @geometry = nil
    end

    def file(path)
      @original = path
      self
    end
    
    def encode(format)
      @encode = format
      self
    end
    
    def square(size)
      size = size.to_i
      d = size * 2
      @square = "-thumbnail x#{d} -resize '#{d}x<' -resize 50% -gravity center -crop #{size}x#{size}+0+0"
      self
    end
    
    def greyscale
      @greyscale = '-colorspace Gray'
      self
    end
    
    def thumb(geometry)
      @geometry = case geometry
      when RESIZE_GEOMETRY
        resize(geometry)
      when CROPPED_RESIZE_GEOMETRY
        resize_and_crop(:width => $1, :height => $2, :gravity => $3)
      when CROP_GEOMETRY
        crop(
          :width => $1,
          :height => $2,
          :x => $3,
          :y => $4,
          :gravity => $5
        )
      else raise ArgumentError, "Didn't recognise the geometry string #{geometry}"
      end
      self
    end

    def mime_type
      ext = @encode ? ".#{@encode}" : File.extname(@original) 
      Rack::Mime.mime_type ext
    end
    
    # Utility method to test that all commands are working
    #
    def to_file(path)
      File.open(path, 'w+') do |f|
        f.write(`#{command}`)
      end
    end

    def command
      raise ArgumentError, "no original file provided. Do commander.file('some_file.jpg')" unless @original
      cmd = []
      cmd << @geometry if @geometry
      cmd << @greyscale if @greyscale
      cmd << @square if @square # should clear command
      if @encode
        cmd << "#{@encode}:-" # to stdout
      else
        cmd << '-'
      end
      
      "convert #{File.join(@base_path, @original)} " + cmd.join(' ')
    end
    
    private
    
    def resize(geometry)
      "-resize \"#{geometry}\""
    end
    
    def crop(opts={})
      width   = opts[:width]
      height  = opts[:height]
      gravity = GRAVITIES[opts[:gravity]]
      x       = "#{opts[:x] || 0}"
      x = '+' + x unless x[/^[+-]/]
      y       = "#{opts[:y] || 0}"
      y = '+' + y unless y[/^[+-]/]
      repage  = opts[:repage] == false ? '' : '+repage'
      resize  = opts[:resize]
  
      "#{"-resize #{resize} " if resize}#{"-gravity #{gravity} " if gravity}-crop #{width}x#{height}#{x}#{y} #{repage}"
    end
    
    def resize_and_crop(opts={})
      if !opts[:width] && !opts[:height]
        return self
      elsif !opts[:width] || !opts[:height]
        attrs          = identify(temp_object)
        opts[:width]   ||= attrs[:width]
        opts[:height]  ||= attrs[:height]
      end

      opts[:gravity] ||= 'c'

      opts[:resize]  = "#{opts[:width]}x#{opts[:height]}^^"
      crop(opts)
    end

  end
  
end