require 'rest-client'
require 'json'

module OpenRegister
  class RegisterClient
    def initialize(register, phase)
      @register = register
      @phase = phase

      refresh_data
    end

    def refresh_data
      @items = []
      @entries = { user: [], system: [] }
      @records = { user: {}, system: {} }

      rsf = download_rsf(@register, @phase)
      parse_rsf(rsf)
    end

    def get_entries
      @entries[:user]
    end

    def get_records
      @records[:user].map { |_k, v| v.last }
    end

    def get_metadata_records
      @records[:system].map { |_k, v| v.last }
    end

    def get_field_definitions
      get_metadata_records.select { |record| record[:key].start_with?('field:') }
    end

    def get_register_definition
      get_metadata_records.select { |record| record[:key].start_with?('register:') }.first
    end

    def get_custodian
      get_metadata_records.select { |record| record[:key] == 'custodian'}.first
    end

    def get_records_with_history
      @records[:user]
    end

    def get_current_records
      get_records.select { |record| record[:item]['end-date'].blank? }
    end

    def get_expired_records
      get_records.select { |record| record[:item]['end-date'].present? }
    end

    private

    def download_rsf(register, phase)
      RestClient.get("https://#{register}.#{phase}.openregister.org/download-rsf")
    end

    def parse_rsf(rsf)
      rsf.each_line do |line|
        line.slice!("\n")
        params = line.split("\t")

        command = params[0]

        if command == 'add-item'
          @items << parse_item(params[1])
        elsif command == 'append-entry'
          key = params[2]
          entry_number = @entries[:user].count + 1
          entry_timestamp = params[3]
          current_item_hash = params[4]
          record = parse_entry(key, entry_number, entry_timestamp, current_item_hash, JSON.parse(@items.find { |item| item[:hash] == current_item_hash }[:item]))

          if params[1] == 'user'
            if !@records[:user].key?(key)
              @records[:user][key] = []
            end

            @records[:user][key] << record
            @entries[:user] << record
          else
            if !@records[:system].key?(key)
              @records[:system][key] = []
            end

            @records[:system][key] << record
            @entries[:system] << record
          end
        end
      end
    end

    def parse_item(item_json)
      payload_sha = Digest::SHA256.hexdigest item_json
      { hash: 'sha-256:' + payload_sha, item: item_json }
    end

    def parse_entry(key, entry_number, entry_timestamp, hash, current_item)
      { key: key, entry_number: entry_number, timestamp: entry_timestamp, hash: hash, item: current_item }
    end
  end
end