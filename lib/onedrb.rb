#!/usr/bin/env ruby

# file: onedrb.rb

# Description: Makes it convenient to make an object remotely accessible.

require 'drb'
require 'c32'

# Note: The Server object can also use a default Hash object.
#       Which allows the Client object to define what user-defined objects the server
#       should host dynamically.


class OneDrbError < Exception
end


module OneDrb

  class Server
    using ColouredText

    def initialize(host: '127.0.0.1', port: (49152..65535).to_a.sample.to_s,
                    obj: Hash.new, log: nil)

      log.info self.class.to_s + '/initialize: active' if log

      @host, @port, @log = host, port, log

      if obj then
        @obj = obj
      else
        msg = "No object supplied!".error
        puts msg
        raise OneDrbError, msg
      end

      log.info self.class.to_s +'/initialize: completed' if log

    end

    def start()

      @log.info self.class.to_s +'/start: active' if @log
      puts (self.class.to_s + " running on port " + @port).info
      DRb.start_service "druby://#{@host}:#{@port}", @obj
      DRb.thread.join

    end

  end


  class Client
    using ColouredText

    def initialize(host: '127.0.0.1', port: nil)

      DRb.start_service

      puts 'no port supplied'.error unless port

      puts ('client connecting to port ' + port).info
      @obj = DRbObject.new_with_uri("druby://#{host}:#{port}")

    end

    # Makes a remote call in 1 line of code using a URI
    # e.g. OneDrb::Client.call 'odrb://clara.home/fun/go?arg=James&age=49'
    #
    def self.call(s, port: nil)

      r = s.match(/^odrb:\/\/([^\/]+)\/([^\/]+)\/([^\?]+)\??(.*)/).captures

      rawhostname, service, methodname, rawargs = r
      hostname, rawport = rawhostname.split(':',2)
      port ||= rawport

      rawargs2 = rawargs&.split('&').map {|x| x.split('=')}

      a1, a2 = rawargs2.partition do |field, value|
        field.downcase.to_sym == :arg
      end

      h = a2.map {|k,v| [k.to_sym, v]}.to_h
      a = a1.map(&:last)

      client = OneDrb::Client.new host: hostname, port: port
      proc1 = client[service].method(methodname.to_sym)

      h.any? ? proc1.call(*a, **h) : proc1.call(*a)

    end

    def remote()
      @obj
    end

    def method_missing(sym, *args)

      if args.last.is_a?(Hash) then
        @obj.send(sym, *args[0..-2], **args.last)
      else
        @obj.send(sym, *args)
      end

    end

  end

end
