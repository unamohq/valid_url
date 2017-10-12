# frozen_string_literal: true
require 'net/http'
require 'openssl'
require 'yaml'

module ValidUrl
  class DomainListUpdater
    class << self
      ZONES_PATH        = File.dirname(__FILE__) + '/config/zones.yml'
      TLD_LIST_ENDPOINT = 'https://data.iana.org/TLD/tlds-alpha-by-domain.txt'

      def update
        save_yml(domains)
      end

      private

      def save_yml(domains)
        File.open(ZONES_PATH, 'w') do |file|
          file.write domains.to_yaml
        end
      end

      def domains
        tld_list_response.body
          .downcase
          .split("\n")
          .reject { |domain| domain.start_with?('#') } # reject comments
      end

      def tld_list_response
        uri  = URI.parse(TLD_LIST_ENDPOINT)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER

        http.request(Net::HTTP::Get.new(uri.request_uri))
      end
    end
  end
end
