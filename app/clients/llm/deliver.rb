module Llm
  class Deliver < Connection
    def self.answer(prompt)
      send_request("post", "/api/generate", prompt)
    end
  end
end
