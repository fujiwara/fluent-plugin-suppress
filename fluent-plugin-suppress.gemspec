# -*- mode:ruby -*-

Gem::Specification.new do |gem|
  gem.authors       = ['FUJIWARA Shunichiro']
  gem.email         = ['fujiwara.shunichiro@gmail.com']
  gem.description   = 'Fluentd filter plugin to suppress same messages'
  gem.summary       = 'Fluentd filter plugin to suppress same messages'
  gem.homepage      = 'https://github.com/fujiwara/fluent-plugin-suppress'
  gem.license       = 'Apache-2.0'

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'fluent-plugin-suppress'
  gem.require_paths = ['lib']
  gem.version       = '0.0.7.2'

  gem.add_runtime_dependency 'fluentd', ['>= 0.14.8', '< 2']
  gem.add_development_dependency 'rake', '>= 0.9.2'
  gem.add_development_dependency 'test-unit', '>= 3.0'
end
