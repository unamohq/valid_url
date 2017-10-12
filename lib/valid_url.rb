# -*- encoding : utf-8 -*-
require "addressable/uri"
require "resolv"
require "simpleidn"

module ActiveModel
  module Validations
    class UrlValidator < ActiveModel::EachValidator
      PROTOCOLS = ['http', 'https']
      ZONES     = YAML.load File.read(File.dirname(__FILE__) + '/valid_url/config/zones.yml')

      def validate_each(record, attribute, value)
        begin
          url = ensure_protocol(value)
          uri = Addressable::URI.parse(url)
        rescue
          invalid = true
        end

        unless !invalid && valid_scheme?(uri.scheme) && valid_host?(uri.host) && valid_path?(uri.path)
          record.errors[attribute] << (options[:message] || "is an invalid URL")
        end
      end

      protected

      # add common protocol by default
      def ensure_protocol(url)
        if url[/\A(#{PROTOCOLS.join('|')}):\/\//i]
          url
        else
          "http://" + url
        end
      end

      # http and https are accepted
      def valid_scheme?(scheme)
        UrlValidator::PROTOCOLS.include?(scheme.mb_chars.downcase.to_s)
      end

      def valid_host?(host)
        return false unless host.present? && valid_characters?(host)
        labels = host.split('.')
        valid_length?(host) && valid_labels?(labels) && (valid_ip?(host) || valid_zone?(labels.last))
      end

      # each label must be between 1 and 63 characters long
      def valid_labels?(labels)
        labels.count >= 2 && labels.all?{ |label| label.length >= 1 && label.length <= 63 }
      end

      # entire hostname has a maximum of 253 characters
      def valid_length?(host)
        host.length <= 253
      end

      # only existent domain name zones
      def valid_zone?(zone)
        normalized_zone = zone.mb_chars.downcase.to_s
        UrlValidator::ZONES.include?(normalized_zone) || UrlValidator::ZONES.include?(SimpleIDN.to_ascii(normalized_zone))
      end

      # check if host is an ip-address
      def valid_ip?(host)
        host =~ Resolv::IPv4::Regex
      end

      # disallow some prohibited characters
      def valid_characters?(host)
        !host[/[\s\!\\"$%&'\(\)*+,:;<=>?@\[\]^|£§°ç\/]/] && host.last != '.'
      end

      # disallow blank caracters in the path
      def valid_path?(path)
        !path[/\s/]
      end

    end
  end
end
