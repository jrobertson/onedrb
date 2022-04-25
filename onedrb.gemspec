Gem::Specification.new do |s|
  s.name = 'onedrb'
  s.version = '0.4.1'
  s.summary = 'Makes it convenient to make an object remotely accessible.'
  s.authors = ['James Robertson']
  s.files = Dir['lib/onedrb.rb']
  s.add_runtime_dependency('c32', '~> 0.3', '>=0.3.0')
  s.add_runtime_dependency('app-mgr', '~> 0.4', '>=0.4.0')
  s.signing_key = '../privatekeys/onedrb.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'digital.robertson@gmail.com'
  s.homepage = 'https://github.com/jrobertson/onedrb'
end
