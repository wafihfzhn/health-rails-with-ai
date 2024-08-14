module Dekontaminasi
  class Connection
    BASE_API_URL = "https://dekontaminasi.com"

    class << self
      def send_request(http_verb, path, region)
        response = connection.send(http_verb) do |req|
          req.url path
          req.body = {}
        end

        hospitals_by_region(response.body, region)
      end

      private

      def connection
        Faraday.new(url: BASE_API_URL) do |conn|
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.adapter Faraday.default_adapter
        end
      end

      def hospitals_by_region(response_body, region)
        covid_hospitals = JSON.parse(response_body)
        covid_hospitals.select do |hospital|
          hospital["region"].include?(region)
        end
      end
    end
  end
end
