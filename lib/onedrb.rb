#!/usr/bin/env ruby

# file: onedrb.rb

# Description: Makes it convenient to make an object remotely accessible.

require 'drb'
require 'c32'


class OneDrbError < Exception
end


module OneDrb

  class Server
    using ColouredText

    def initialize(host: '127.0.0.1', port: (49152..65535).to_a.sample.to_s, 
                    obj: nil, log: nil)

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

    def method_missing(sym, *args)
      @obj.send(sym, *args)
    end

  end 

end
