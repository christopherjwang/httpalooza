module HTTPalooza
  class Request
    STANDARD_METHODS = [:get, :post, :put, :patch, :delete, :options, :head]

    attr_reader :url, :method, :params, :payload, :headers

    def initialize(url, method, options = {})
      @url = url
      @method = method
      @params = options[:params] || {}
      @payload = options[:payload]
      @headers = Rack::Utils::HeaderHash.new(options[:headers] || {})

      normalize_url!
    end

    def ssl?
      !!(url.to_s =~ /^https/)
    end

    STANDARD_METHODS.each do |verb|
      define_method(:"#{verb}?") do
        method == verb
      end
    end

    private
    def normalize_url!
      raise ArgumentError, "Invalid URL: #{url}" unless url.to_s =~ /^http/
      @url = url.kind_of?(Addressable::URI) ? url : Addressable::URI.parse(url)
      @url.query_values = (@url.query_values || {}).merge(params)
      @url.normalize!
    end
  end
end