# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'
require 'hako/app_container'
require 'hako/scripts/switch_hitter'

RSpec.describe Hako::Scripts::SwitchHitter do
  let(:script) { described_class.new(app, options, dry_run: false) }
  let(:app) {
    double(
      'Hako::Application',
      id: 'nanika',
      yaml: {
        'scheduler' => {
          'elb_v2' => {
            'listeners' => listeners
          }
        },
        'region' => 'ap-northeast-1'
      }
    )
  }
  let(:options) do
    {
      'type' => 'switch_hitter',
    }
  end
  let(:listeners) do
    [
      { 'port' => 80, 'protocol' => 'HTTP' },
      { 'port' => 443, 'protocol' => 'HTTPS' },
    ]
  end
  let(:app_container) { Hako::AppContainer.new(app, options, dry_run: false) }
  let(:backend_port) { 3000 }
  let(:front_container) { Hako::Container.new(app, {}, dry_run: false) }
  let(:containers) { { 'app' => app_container, 'front' => front_container } }
  let(:elb_v2_client) { double('Aws::ElasticLoadBalancingV2::Client') }
  let(:describe_response) {
    double(
      'Aws::ElasticLoadBalancingV2::Types::DescribeLoadBalancersOutput',
      load_balancers: [double('Aws::ElasticLoadBalancingV2::Types::LoadBalancer', dns_name: 'dns_name')]
    )
  }

  before do
    allow(script).to receive(:elb_v2).and_return(elb_v2_client)
    allow(elb_v2_client).to receive(:describe_load_balancers).and_return(describe_response)
    stub_request(:get, /dns_name/).
      to_return(status: 200, body: "started", headers: {})
  end

  describe '#deploy_finished' do
    context 'http' do
      context 'default enable path' do
        let(:options) do
          {
            'type' => 'switch_hitter',
            'endpoint' => {
              'path' => '/switch_path',
            }
          }
        end

        it 'should hit switch endpoint' do
          expect(elb_v2_client).to receive(:describe_load_balancers).with(names: ['hako-nanika'])
          script.deploy_finished(containers)
        end
      end

      context 'switch return 404' do
        let(:options) do
          {
            'type' => 'switch_hitter',
            'endpoint' => {
              'path' => '/switch_path',
            }
          }
        end

        before do
          stub_request(:get, /dns_name/).
            to_return(status: 404, body: 'not found', headers: {})
        end

        it 'should raise Hako::Error' do
          expect(elb_v2_client).to receive(:describe_load_balancers).with(names: ['hako-nanika'])
          expect { script.deploy_finished(containers) }.to raise_error(Hako::Error)
        end
      end

      context 'custom enable path' do
        let(:options) do
          {
            'type' => 'switch_hitter',
            'endpoint' => {
              'proto' => 'http',
              'host' => 'example.com',
              'port' => 10080,
              'path' => '/custom_path',
            }
          }
        end

        before do
          stub_request(:get, /example.com/).
            to_return(status: 200, body: "started", headers: {})
        end

        it 'should hit switch endpoint' do
          expect { script.deploy_finished(containers) }.not_to raise_error
        end
      end
    end

    context 'https' do
      let(:options) do
        {
          'type' => 'switch_hitter',
          'endpoint' => {
            'path' => '/switch_path',
          }
        }
      end

      let(:listeners) do
        [
          { 'port' => 443, 'protocol' => 'HTTPS' }
        ]
      end

      it 'should hit switch endpoint' do
        expect(elb_v2_client).to receive(:describe_load_balancers).with(names: ['hako-nanika'])
        script.deploy_finished(containers)
      end
    end
  end
end
