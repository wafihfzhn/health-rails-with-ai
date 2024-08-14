module Dekontaminasi
  class Covid < Connection
    def self.hospitals(region)
      send_request("get", "/api/id/covid19/hospitals", region)
    end
  end
end
