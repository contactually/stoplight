# coding: utf-8

module Stoplight
  module Notifier
    # @see Base
    class Pagerduty < Base
      include Generic

      # @return [::Slack::Notifier]
      def pagerduty
        @object
      end

      # @see Base#notify
      def notify(light, from_color, to_color, error)
        message = formatter.call(light, from_color, to_color, error)

        incident_key = "breaker_#{light.name}"
        if to_color == Stoplight::Color::RED
          pagerduty.trigger(message, incident_key: incident_key)
        elsif to_color == Stoplight::Color::GREEN
          incident = pagerduty.get_incident(incident_key)
          incident.resolve if incident.present?
        end

        message
      end
    end
  end
end
