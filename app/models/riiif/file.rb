require 'open3'
require 'mkmf'
module Riiif
  class File
    include Open3
    include ActiveSupport::Benchmarkable

    attr_reader :path

    delegate :logger, to: :Rails

    # @param input_path [String] The location of an image file
    def initialize(input_path, tempfile = nil)
      @path = input_path
      @tempfile = tempfile # ensures that the tempfile will stick around until this file is garbage collected.
    end

    def self.read(stream, ext)
      create(ext) do |f|
        while (chunk = stream.read(8192))
          f.write(chunk)
        end
      end
    end

    def self.create(ext = nil, _validate = true, &block)
      tempfile = Tempfile.new(['mini_magick', ext.to_s.downcase])
      tempfile.binmode
      block.call(tempfile)
      tempfile.close
      new(tempfile.path, tempfile)
    ensure
      tempfile.close if tempfile
    end

    def extract(options)
      command = if mime_type(path).match(/tiff/) && find_executable('tifftopnm')
                  extract_tifftopnm(options)
                else
                  extract_imagemagick(options)
                end
      execute(command)
    end

    def mime_type(path)
      IO.popen(["file", "--brief", "--mime-type", path], in: :close, err: :close) { |io| io.read.chomp }
    end

    def extract_tifftopnm(options)
      command = ["tifftopnm -byrow #{path}"]
      if options[:crop]
        w, h, x, y = options[:crop].split(/[x\+]/)
        command << "pamcut #{x} #{y} #{w} #{h}"
      end

      if options[:size]
        w, h = options[:size].split("x")
        command << "pnmscalefixed -xysize #{w} #{h}" if h.present?  && w.present?
        command << "pnmscalefixed -xsize #{w}"       if !h.present? && w.present?
        command << "pnmscalefixed -ysize #{h}"       if h.present?  && !w.present?
      end

      # ignore quality
      command << "pnmtojpeg -quality 95"
      command.join(' | ')
    end

    def extract_imagemagick(options)
      command = 'convert'
      command << " -crop #{options[:crop]}" if options[:crop]
      command << " -resize #{options[:size]}" if options[:size]
      if options[:rotation]
        command << " -virtual-pixel white +distort srt #{options[:rotation]}"
      end

      case options[:quality]
      when 'grey'
        command << ' -colorspace Gray'
      when 'bitonal'
        command << ' -colorspace Gray'
        command << ' -type Bilevel'
      end
      command << " #{path} #{options[:format]}:-"
    end

    def info
      return @info if @info
      height, width = execute("identify -format %hx%w #{path}").split('x')
      @info = { height: Integer(height), width: Integer(width) }
    end

    private

      def execute(command)
        out = nil
        benchmark("Riiif executed #{command}") do
          stdin, stdout, stderr, wait_thr = popen3(command)
          stdin.close
          stdout.binmode
          out = stdout.read
          stdout.close
          err = stderr.read
          stderr.close
          raise "Unable to execute command \"#{command}\"\n#{err}" unless wait_thr.value.success?
        end
        out
      end
  end
end
