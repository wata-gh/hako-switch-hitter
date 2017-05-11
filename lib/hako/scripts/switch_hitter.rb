require 'hako'
require 'hako/error'
require 'hako/script'
require 'net/http'
require 'uri'

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

      # @return [URI]
      def endpoint_uri
        @uri ||= URI.parse(endpoint)
      end

      # @return [String]
      def endpoint_scheme
        raise Error.new("Switch hitter endpoint scheme must be http or https") unless %w/http https/.include?(endpoint_uri.scheme)
        endpoint_uri.scheme
      end

      # @return [String]
      def endpoint_host
        endpoint_uri.host
      end

      # @return [Fixnum]
      def endpoint_port
        endpoint_uri.port
      end

      # @return [String]
      def endpoint_path
        endpoint_uri.path
      end

      # @return [Net::HTTP]
      def http(host, port)
        Net::HTTP.new(host, port)
      end

      # @return [nil]
      def hit_switch
        Hako.logger.info("Switch endpoint #{endpoint}")

        net_http = http(endpoint_host, endpoint_port)
        net_http.use_ssl = endpoint_scheme == 'https'

        if @dry_run
          Hako.logger.info("Switch hitter will request #{endpoint} [dry-run]")
          return
        end

        net_http.start do
          req = Net::HTTP::Get.new(endpoint_uri.request_uri)
          res = net_http.request(req)
          unless res.code == '200'
            raise Error.new("Switch hitter HTTP Error: #{res.code}: #{res.body}")
          end
          Hako.logger.info("Enabled #{endpoint} at #{res.body}")
        end
      end
    end
  end
end
