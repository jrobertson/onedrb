Gem::Specification.new do |s|
  s.name = 'onedrb'
  s.version = '0.1.0'
  s.summary = 'Makes it convenient to make an object remotely accessible.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/onedrb.rb']
  s.add_runtime_dependency('c32', '~> 0.2', '>=0.2.0')
  s.signing_key = '../privatekeys/onedrb.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/onedrb'
end
