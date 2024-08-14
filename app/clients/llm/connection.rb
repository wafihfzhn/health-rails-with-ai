module Llm
  class Connection
    BASE_API_URL = "http://localhost:11434"
    class << self
      def send_request(http_verb, path, prompt)
        response = connection.send(http_verb) do |req|
          req.url path
          req.body = request_body(prompt)
        end

        response_answer = response.body["response"].strip
        action = action_from(response_answer)
        return extract_answer(response_answer) if action.nil?

        response = connection.send(http_verb) do |req|
          req.url path
          req.body = request_body(final_prompt(prompt, action[:result]))
        end

        extract_answer(response.body["response"].strip)
      end

      private

      def connection
        Faraday.new(url: BASE_API_URL) do |conn|
          conn.request :json
          conn.response :json, content_type: /\bjson$/
          conn.adapter Faraday.default_adapter
        end
      end

      def system_message
        <<~MESSAGE
          You run in a process of Question, Thought, Action, Observation.

          Use Thought to describe your thoughts about the question you have been asked.
          Observation will be the result of running those actions.

          use Action to run one of these actions available to you:
          - If the question is about hospitals, use find_hospital: region
          - Otherwise, use lookup: terms

          Here are some sample sessions.

          Question: Di mana saya bisa menemukan rumah sakit COVID di suatu daerah
          Thought: Ini tentang rumah sakit COVID di daerah tertentu, saya perlu mencari daftar rumah sakit di daerah tersebut.
          Action: find_hospital: daerah
          Observation: Saya menemukan beberapa rumah sakit COVID di suatu daerah.
          Answer: Berikut adalah daftar rumah sakit COVID di suatu daerah.

          Let's go!
        MESSAGE
      end

      def request_body(question)
        {
          model: "koesn/kesehatan-7b-v0.1",
          prompt: "#{system_message}\n\nQuestion: $#{question}",
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

      def final_prompt(question, observation)
        <<~PROMPT
          #{question}
          Observation: #{observation}
          Thought: Now I have the answer.
          Answer:
        PROMPT
      end

      def extract_answer(text)
        marker = "Answer:"
        pos = text.rindex(marker)
        return "Kami belum mendapatkan data terkait yang kamu tanyakan?" if pos.nil?

        text[(pos + marker.length)..-1].strip
      end

      def action_from(text)
        marker = "Action:"
        pos = text.rindex(marker)
        return nil if pos.nil?

        subtext = "#{text[pos..-1]} \n"
        match = /Action:\s*(.*?)\n/.match(subtext)
        action = match[1] if match
        return nil if action.nil?

        separator = ":"
        sep = action.index(separator)
        return nil if sep.nil?

        fn_name = action[0...sep].strip
        fn_args = action[(sep + 1)..-1].strip

        case fn_name
        when "lookup"
          nil
        when "find_hospital"
          if fn_args.present?
            covid_hospitals = Dekontaminasi::Covid.hospitals(fn_args.upcase)
            result = result_hospitals(covid_hospitals)

            puts "ACTION: find_hospital", { args: fn_args, result: result }
            { action: action, name: fn_name, args: fn_args, result: result }
          else
            puts "Invalid arguments for find_hospital action"
            nil
          end
        else
          puts "Not recognized action:", { action: action, name: fn_name, args: fn_args }
          nil
        end
      end

      def result_hospitals(covid_hospitals)
        return "Kami belum memiliki data Rumah Sakit yang anda maksud" if covid_hospitals.blank?

        hospital_names = covid_hospitals.map do |hospital|
          "#{hospital["name"]} beralamat di #{hospital["address"]}"
        end
        hospital_names.join(", ")
      end
    end
  end
end
