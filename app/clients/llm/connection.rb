module Llm
  class Connection
    LLM_BASE_API_URL = "http://localhost:11434";

    class << self
      def send_request(http_verb, path, prompt)
        response = connection.send(http_verb) do |req|
          req.url path
          req.body = request_body(prompt)
        end

        json_response(response)
      end

      private

      def connection
        Faraday.new(url: LLM_BASE_API_URL) do |conn|
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.adapter Faraday.default_adapter
        end
      end

      def request_body(prompt)
        {
          model: "mistral-openorca",
          prompt: prompt,
          options: {
            num_predict: 200,
            temperature: 0,
            top_k: 20
          },
          stream: false
        }
      end

      def json_response(faraday_response)
        {
          status: faraday_response.status,
          body: faraday_response.body,
        }.with_indifferent_access
      end
    end
  end
end
