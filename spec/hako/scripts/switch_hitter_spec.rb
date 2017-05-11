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
      yaml: {}
    )
  }
  let(:options) do
    {
      'type' => 'switch_hitter',
    }
  end
  let(:app_container) { Hako::AppContainer.new(app, options, dry_run: false) }
  let(:front_container) { Hako::Container.new(app, {}, dry_run: false) }
  let(:containers) { { 'app' => app_container, 'front' => front_container } }

  before do
    stub_request(:get, /example.com/).
      to_return(status: 200, body: "started", headers: {})
  end

  describe '#deploy_finished' do
    context 'invalid protocol' do
      let(:options) do
        {
          'type' => 'switch_hitter',
          'endpoint' => 'ftp://example.com/switch_path',
        }
      end

      it 'should raise Hako::Error' do
        expect { script.deploy_finished(containers) }.to raise_error(Hako::Error)
      end
    end

    context 'http' do
      context 'with port' do
        let(:options) do
          {
            'type' => 'switch_hitter',
            'endpoint' => 'http://example.com:10080/switch_path?hoge=1',
          }
        end

        it 'should hit switch endpoint' do
          script.deploy_finished(containers)
        end
      end

      context 'switch return 404' do
        let(:options) do
          {
            'type' => 'switch_hitter',
            'endpoint' => 'http://example.com/switch_path',
          }
        end

        before do
          stub_request(:get, /example.com/).
            to_return(status: 404, body: 'not found', headers: {})
        end

        it 'should raise Hako::Error' do
          expect { script.deploy_finished(containers) }.to raise_error(Hako::Error)
        end
      end
    end

    context 'https' do
      context 'with port' do
        let(:options) do
          {
            'type' => 'switch_hitter',
            'endpoint' => 'https://example.com:443/switch_path',
          }
        end

        it 'should hit switch endpoint' do
          script.deploy_finished(containers)
        end
      end

      context 'witout port' do
        let(:options) do
          {
            'type' => 'switch_hitter',
            'endpoint' => 'https://example.com/switch_path',
          }
        end

        it 'should hit switch endpoint' do
          script.deploy_finished(containers)
        end
      end
    end
  end
end
