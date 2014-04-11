# -*- encoding: utf-8 -*-
# -*- mode:ruby -*-

Gem::Specification.new do |gem|
  gem.authors       = ["FUJIWARA Shunichiro"]
  gem.email         = ["fujiwara.shunichiro@gmail.com"]
  gem.description   = %q{Fluentd plugin to suppress same messages}
  gem.summary       = %q{Fluentd plugin to suppress same messages}
  gem.homepage      = "https://github.com/fujiwara/fluent-plugin-suppress"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "fluent-plugin-suppress"
  gem.require_paths = ["lib"]
  gem.version       = "0.0.4"

  gem.add_development_dependency "fluentd"
  gem.add_runtime_dependency "fluentd"
end
