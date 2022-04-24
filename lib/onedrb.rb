#!/usr/bin/env ruby

# file: onedrb.rb

# Description: Makes it convenient to make an object remotely accessible.

require 'drb'
require 'c32'
require 'app-mgr'


# Note: The Server object can also use a default ServiceMgr object.
#       Which allows multiple services (user-defined objects) to be
#       hosted dynamically.
# OneDrb recommended port: 57844 (as this port is recognised by the RSC gem)
#
class ServiceMgr < AppMgr

  def initialize(rsf: nil, debug: false)
    super(rsf: rsf, type: 'service', debug: debug)
    @services = @app
  end


  def call(service, methodname, *a)

    return @services[service.to_sym][:running] unless methodname
    proc1 = @services[service.to_sym][:running].method(methodname.to_sym)
    a.last.is_a?(Hash) ? proc1.call(*a[0..-2], **a.last) : proc1.call(*a)

  end


  # OneDRb version 2; Allows multiple user-defined objects to be
  #                   served from 1 DRb service
  #
  # not used by any client, but may be in future
  #
  #def odrb2?()
  #  true
  #end

  def services()
    @services.map do |key, object|
      next unless object[:running]
      [key, object[:running].public_methods - Object.public_methods]
    end.compact
  end

  def stop(service)
    super(service).sub('app', 'service')
  end

  def unload(service)
    super(service).sub('app', 'service')
  end

  def method_missing(sym, *args)
    #puts 'servicemgr sym: ' + sym.inspect
    #puts 'args: ' + args.inspect
  end
end


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
      parent = self
      @obj&.services.each do |name, methods|

        make_class(name, methods)

      end

    end

    # Makes a remote call in 1 line of code using a URI
    # Only available when using the ServiceMgr as the server object;
    #
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

      if h.any? then

        if a.any? then
          client.call service.to_sym, methodname.to_sym, *a, **h
        else
          client.call service.to_sym, methodname.to_sym, **h
        end

      elsif a.any?

        client.call service.to_sym, methodname.to_sym, *a

      else

        client.call service.to_sym, methodname.to_sym

      end

    end

    def remote()
      @obj
    end

    def restart(service)

      return unless @obj.respond_to? :services

      @obj.restart(service)
      found = @obj.services.assoc(service)
      make_class(*found) if found.any?
    end

    def method_missing(sym, *args)

      if args.last.is_a?(Hash) then
        @obj.send(sym, *args[0..-2], **args.last)
      else
        @obj.send(sym, *args)
      end

    end

    private

    def make_class(name, methods)

      class_name = name.capitalize
      klass = Object.const_set(class_name,Class.new)

      klass.class_eval do
        methods.each do |method_name|
          define_method method_name do |*args|
            parent.call name, method_name, *args
          end
        end
      end

      define_singleton_method name do
        klass.new
      end

    end

  end

end



# Note: The Server object can also use a default ServiceMgr object.
#       Which allows multiple services (user-defined objects) to be
#       hosted dynamically.


class ServiceMgr

  def initialize()
    @services = {}
  end


  def call(service, methodname, *a)

    proc1 = @services[service.to_sym].method(methodname.to_sym)
    a.last.is_a?(Hash) ? proc1.call(*a[0..-2], **a.last) : proc1.call(*a)

  end

  def [](key)
    @services[key]
  end

  def []=(key, value)
    @services[key] = value

    define_singleton_method key do
      @services[key]
    end
  end

  def services()
    @services.map do |key, object|
      [key, object.public_methods - Object.public_methods]
    end
  end

  def method_missing(sym, *args)
    puts 'servicemgr sym: ' + sym.inspect
    puts 'args: ' + args.inspect
  end
end


class OneDrbError < Exception
end


module OneDrb

  class Server
    using ColouredText

    def initialize(host: '127.0.0.1', port: (49152..65535).to_a.sample.to_s,
                    obj: ServiceMgr.new, log: nil)

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
      parent = self
      @obj&.services.each do |name, methods|

        class_name = name.capitalize
        klass = Object.const_set(class_name,Class.new)

        klass.class_eval do
          methods.each do |method_name|
            define_method method_name do |*args|
              parent.call name, method_name, *args
            end
          end
        end

        define_singleton_method name do
          klass.new
        end

      end

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

      if h.any? then

        if a.any? then
          client.call service.to_sym, methodname.to_sym, *a, **h
        else
          client.call service.to_sym, methodname.to_sym, **h
        end

      elsif a.any?

        client.call service.to_sym, methodname.to_sym, *a

      else

        client.call service.to_sym, methodname.to_sym

      end

    end

    def remote()
      @obj
    end

    def method_missing(sym, *args)

      puts '@obj.class: ' + @obj.class.inspect

      if args.last.is_a?(Hash) then
        @obj.send(sym, *args[0..-2], **args.last)
      else
        @obj.send(sym, *args)
      end

    end

  end

end
