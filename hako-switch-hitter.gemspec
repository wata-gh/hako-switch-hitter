# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'hako-switch-hitter'
  spec.version       = '0.1.3'
  spec.authors       = ['wata']
  spec.email         = ['wata.gm@gmail.com']

  spec.summary       = 'Hit switch endpoint on deploy_finished'
  spec.description   = 'Hit switch endpoint on deploy_finished'
  spec.homepage      = 'https://github.com/wata-gh/hako-switch-hitter'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'hako'
  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'pry-byebug'
end
