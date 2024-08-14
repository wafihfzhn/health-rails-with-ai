module Llm
  class Connection
    LLM_BASE_API_URL = "http://localhost:11434";
    SYSTEM_MESSAGE = <<~MESSAGE
      You run in a process of Question, Thought, Action, Observation.

      Use Thought to describe your thoughts about the question you have been asked.
      Observation will be the result of running those actions.
      Finally at the end, state the Answer.

      Here are some sample sessions.

      # Do stuff here

      Let's go!
    MESSAGE

    class << self
      def send_request(http_verb, path, prompt)
        response = connection.send(http_verb) do |req|
          req.url path
          req.body = request_body(prompt)
        end

        response.body["response"]
        # answer = response.body["response"].strip
        # extract_answer(answer)
      end

      private

      def connection
        Faraday.new(url: LLM_BASE_API_URL) do |conn|
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.adapter Faraday.default_adapter
        end
      end

      def request_body(question)
        {
          model: "koesn/kesehatan-7b-v0.1",
          prompt: question,
          # prompt: "#{SYSTEM_MESSAGE}\n\n#{question}",
          options: {
            mirostat: 0,
            mirostat_eta: 0.1,
            mirostat_tau: 5,
            num_ctx: 8192,
            repeat_last_n: 64,
            repeat_penalty: 1.18,
            temperature: 0.16,
            top_k: 40,
            top_p: 0.95
          },
          stream: false
        }
      end

      def extract_answer(text)
        marker = "Answer:"
        pos = text.rindex(marker)
        return "?" if pos.nil?

        answer = text[(pos + marker.length)..-1].strip
        answer
      end

      def think(question)
        prompt = "#{SYSTEM_MESSAGE}\n\n#{question}"
        response = generate(prompt)
        extract_answer(response)
      end
    end
  end
end
