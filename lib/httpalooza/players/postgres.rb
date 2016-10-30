module HTTPalooza
  module Players
    class PostgresPlayer < Base
      introducing! :postgres, %w[pg]

      DATABASE_NAME = 'httpalooza'

      def response
        raise("I don't think Postgres supports request headers...") unless request.headers.empty?

        case request.method
        when :get
          endpoint = request.url
          unless request.payload.nil?
            endpoint += "?#{ payload_to_params }"
          end
          conn.exec("SELECT status, content FROM http_get('#{ endpoint }')") do |result|
            r = result.first
            return Response.new(r['status'], r['content'])
          end

        when :post
          conn.exec(%{ SELECT status, content FROM
                      http_post('#{ request.url }',
                      '#{ payload_to_params }',
                      'application/x-www-form-urlencoded') }
          ) do |result|
            r = result.first
            return Response.new(r['status'], r['content'])
          end

        when :put
          conn.exec(%{ SELECT status, content FROM
                      http_put('#{ request.url }',
                      '#{ payload_to_params }',
                      'application/x-www-form-urlencoded') }
          ) do |result|
            r = result.first
            return Response.new(r['status'], r['content'])
          end

        when :delete
          conn.exec("SELECT status, content FROM http_delete('#{ endpoint }')") do |result|
            r = result.first
            return Response.new(r['status'], r['content'])
          end
        end
      end

      private

      def payload_to_params
        if request.payload.is_a?(Hash)
          request.payload.to_param
        elsif request.payload.is_a?(String)
          begin
            JSON.parse(request.payload).to_param
          rescue JSON::ParserError
            request.payload
          end
        else
          ''
        end
      end

      def conn
        return @conn if @conn
        begin
          @conn ||= PG.connect(:dbname => DATABASE_NAME)
        rescue PG::ConnectionBad
          raise("Cannot connect to database: #{DATABASE_NAME}")
        end
      end
    end
  end
end
