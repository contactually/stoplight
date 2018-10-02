# coding: utf-8

require 'spec_helper'
require 'pagerduty'

RSpec.describe Stoplight::Notifier::Pagerduty do
  it_behaves_like 'a generic notifier'

  it 'is a class' do
    expect(described_class).to be_a(Class)
  end

  it 'is a subclass of Base' do
    expect(described_class).to be < Stoplight::Notifier::Base
  end

  describe '#pagerduty' do
    it 'reads Pagerduty client' do
      pagerduty = Pagerduty.new('WEBHOOK_URL')
      expect(described_class.new(pagerduty).pagerduty).to eql(pagerduty)
    end
  end

  describe '#notify' do
    let(:light) { Stoplight::Light.new(name, &code) }
    let(:name) { ('a'..'z').to_a.shuffle.join }
    let(:code) { -> {} }
    let(:from_color) { Stoplight::Color::GREEN }
    let(:to_color) { Stoplight::Color::RED }
    let(:notifier) { described_class.new(pagerduty) }
    let(:pagerduty) { double(Pagerduty).as_null_object }
    let(:incident_key) { "breaker_#{light.name}" }
    let(:error) { nil }

    context 'when switching from green to red' do
      let(:from_color) { Stoplight::Color::GREEN }
      let(:to_color) { Stoplight::Color::RED }

      it 'triggers an incident for the specific light in Pagerduty' do
        message = notifier.formatter.call(light, from_color, to_color, error)

        expect(pagerduty).to receive(:trigger)
          .with(message, incident_key: incident_key)

        notifier.notify(light, from_color, to_color, error)
      end
    end

    context 'when switching from red to green' do
      let(:from_color) { Stoplight::Color::RED }
      let(:to_color) { Stoplight::Color::GREEN }
      let(:incident) { double(:incident) }

      before do
        allow(pagerduty).to receive(:get_incident)
          .with(incident_key).and_return(incident)
      end

      it 'resolves an incident related to the specific light in Pagerduty' do
        expect(incident).to receive(:resolve)

        notifier.notify(light, from_color, to_color, error)
      end

      context 'if no incident is found for the specified key' do
        before do
          allow(pagerduty).to receive(:get_incident)
            .with(incident_key).and_return(nil)
        end

        it 'does not attempt to resolve an unfound incident' do
          expect(incident).not_to receive(:resolve)
          notifier.notify(light, from_color, to_color, error)
        end
      end
    end
  end
end
