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
        raise Error.new("Switch hitter endpoint is not configured") unless @options['endpoint']
        @options['endpoint']
      end

      # @return [String]
      def endpoint_proto
        proto = endpoint.fetch('proto')
        raise Error.new("Switch hitter proto must be http or https") unless %w/http https/.include?(proto)
        proto
      end

      # @return [String]
      def endpoint_host
        endpoint.fetch('host')
      end

      # @return [Fixnum]
      def wellknown_port
        endpoint_proto == 'https' ? 443 : 80
      end

      # @return [Fixnum]
      def endpoint_port
        endpoint.fetch('port', wellknown_port)
      end

      # @return [String]
      def endpoint_path
        endpoint.fetch('path')
      end

      # @return [Net::HTTP]
      def http(host, port)
        Net::HTTP.new(host, port)
      end

      # @return [String]
      def url
        "#{endpoint_proto}://#{endpoint_host}:#{endpoint_port}#{endpoint_path}"
      end

      # @return [nil]
      def hit_switch
        net_http = http(endpoint_host, endpoint_port)

        Hako.logger.info("Switch endpoint #{url}")
        if endpoint_proto == 'HTTPS'
          net_http.use_ssl = true
        end

        if @dry_run
          Hako.logger.info("Switch hitter will request #{url} [dry-run]")
          return
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
    end
  end
end
