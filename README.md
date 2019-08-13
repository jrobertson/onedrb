# Introducing the onedrb gem

## Server usage

    require 'onedrb'

    class Fun
      def go(s, age: '22')
        "hello %s; age: %s" % [s, age]
      end
    end

    fun = OneDrb::Server.new host: '127.0.0.1', port: '57844', obj: Fun.new
    fun.start

## Client usage

    require 'onedrb'

    fun = OneDrb::Client.new host: '127.0.0.1', port: '57844'
    fun.go 'James', age: '34'
    #=> "hello James; age: 34"

## Resources

* onedrb https://rubygems.org/gems/onedrb

drb onedrb gem remote connection object

