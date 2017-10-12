require 'spec_helper'
require 'valid_url/domain_list_updater'
require 'openssl'

describe ValidUrl::DomainListUpdater do
  context '#update' do
    it 'requests endpoint and updates file' do
      http_mock     = stub('stub')
      file_mock     = stub('stub')
      response_mock = stub('stub')
      buffer        = StringIO.new
      request_body  = "#comment\nzone_1\nzone_2"
      yaml_body     = "---\n- zone_1\n- zone_2\n"

      expect(Net::HTTP).to receive(:new).and_return(http_mock)
      expect(http_mock).to receive(:use_ssl=).with(true)
      expect(http_mock).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER)
      expect(http_mock).to receive(:request).and_return(response_mock)
      expect(response_mock).to receive(:body).and_return(request_body)

      expect(File).to receive(:open).with(described_class.singleton_class::ZONES_PATH, "w").and_yield(buffer)

      described_class.update

      expect(buffer.string).to eq(yaml_body)
    end
  end
end
