# coding: utf-8
lib = File.expand_path('../lib/', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ipaws/version'

Gem::Specification.new do |gem|
  gem.required_ruby_version = '>=2.2.0'

  gem.name          = 'ipaws'
  gem.version       = Ipaws::VERSION
  gem.authors       = ['BaneOfSerenity', 'Brad Cantin', 'Jonathan Chan']
  gem.email         = ['thowe.dev@gmail.com', 'brad.cantin@gmail.com', 'jc@jmccc.com']

  gem.description   = %q{
                         Dev/Devops tool for listing and ssh-ing into secure private-ip only ec2 instances generated
                         using Elastic Beanstalk. Supports filtering IPs by different projects, environments, and
                         blue-green active/inactive flags for the most busiest of devops staff ;-). Supports SSH-ing
                         using different ssh proxy configurations.
                        }
  gem.summary       = %q{AWS EC2 IP Address CLI Management Tool}
  gem.homepage      = 'https://www.github.com/Malwarebytes/ipaws'
  gem.license       = 'MIT'

  gem.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  gem.bindir        = ['bin']
  gem.executables   = gem.files.grep(%r{^bin/}) { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_development_dependency 'bundler', '~> 1.12'
  gem.add_development_dependency 'rake', '~> 10.0'
  gem.add_development_dependency "rspec", "~> 3.0"
  gem.add_development_dependency "pry"
  
  gem.add_runtime_dependency 'thor', '~> 0.19'
  gem.add_runtime_dependency 'awesome_print', '~> 1.6'
  gem.add_runtime_dependency 'aws-sdk', '~>2.3'
end
