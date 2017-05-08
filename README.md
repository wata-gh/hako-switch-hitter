# Hako::Switch::Hitter

Hit endpoint at [hako](https://github.com/eagletmt/hako) script deploy_finished.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hako-switch-hitter'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hako-switch-hitter

## Usage

```yaml
scripts:
  - type: switch_hitter
    endpoint:
      proto: http
      host: example.com
      port: 10080
      path: /switch_endpoint
```

config | detail | required
--- | --- | ---
proto | http or https | false
host | example.com | false
port | 80 | false
path | /switch_endpoint | true

If `proto`, `host`, `port` is not configured, hako-switch-hitter will use ELB v2 address.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/wata-gh/hako-switch-hitter.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

