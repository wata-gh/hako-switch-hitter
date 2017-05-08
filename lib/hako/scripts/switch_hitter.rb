require 'aws-sdk'
require 'hako'
require 'hako/error'
require 'hako/script'
require 'net/http'

module Hako
  module Scripts
    class SwitchHitter < Script

      # @param [Hash] options
      def configure(options)
        @options = options
      end

      # @param [Hash<String, Container>] containers
      # @return [nil]
      def deploy_finished(containers)
        hit_switch
      end

      alias_method :rollback, :deploy_finished

      private

      # @return [Hash]
      def endpoint
        raise Error.new("Switch hitter endpoint is not configured") unless @options[:endpoint]
        @options[:endpoint]
      end

      # @return [String]
      def endpoint_proto
        endpoint[:proto] || protocol
      end

      # @return [String]
      def endpoint_host
        return endpoint[:host] if endpoint[:host]

        load_balancer = describe_load_balancer
        load_balancer.dns_name
      end

      # @return [Fixnum]
      def endpoint_port
        endpoint[:port] || port
      end

      # @return [String]
      def endpoint_path
        raise Error.new("Switch hitter path is not configured") unless endpoint[:path]
        endpoint[:path]
      end

      # @return [Net::HTTP]
      def http(host, port)
        Net::HTTP.new(host, port)
      end

      # @return [nil]
      def hit_switch
        net_http = http(endpoint_host, endpoint_port)

        Hako.logger.info("Switch endpoint #{endpoint_proto.downcase}://#{endpoint_host}:#{endpoint_port}#{endpoint_path}")
        if endpoint_proto.upcase == 'HTTPS'
          net_http.use_ssl = true
          net_http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end

        net_http.start do
          req = Net::HTTP::Get.new(endpoint_path)
          res = net_http.request(req)
          unless res.code == '200'
            raise Error.new("Switch hitter HTTP Error: #{res.code}: #{res.body}")
          end
          Hako.logger.info("Enabled #{endpoint_path} at #{res.body}")
        end
      end

      # @return [String]
      def region
        @app.yaml.fetch(:scheduler).fetch(:region)
      end

      # @return [Fixnum]
      def port
        @app.yaml.fetch(:scheduler).fetch(:elb_v2).fetch(:listeners)[0].port
      end

      # @return [String]
      def protocol
        @app.yaml.fetch(:scheduler).fetch(:elb_v2).fetch(:listeners)[0].protocol
      end

      # @return [Aws::ElasticLoadBalancingV2::Client]
      def elb_v2
        @elb_v2 ||= Aws::ElasticLoadBalancingV2::Client.new(region: region)
      end

      # @return [Aws::ElasticLoadBalancingV2::Types::Listener]
      def describe_listener(load_balancer_arn)
        elb_v2.describe_listeners(load_balancer_arn: load_balancer_arn).listeners[0]
      end

      # @return [Aws::ElasticLoadBalancingV2::Types::LoadBalancer]
      def describe_load_balancer
        elb_v2.describe_load_balancers(names: [name]).load_balancers[0]
      rescue Aws::ElasticLoadBalancingV2::Errors::LoadBalancerNotFound
        nil
      end

      # @return [String]
      def name
        "hako-#{@app.id}"
      end
    end
  end
end
