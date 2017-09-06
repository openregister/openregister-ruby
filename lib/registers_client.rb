module OpenRegister
  class RegistersClient
    def initialize
      @register_clients = {}
    end

    def get_register(register, phase)
      key = register + ':' + phase

      if !@register_clients.key?(key)
        @register_clients[key] = OpenRegister::RegisterClient.new register, phase
      end

      @register_clients[key]
    end
  end
end