require 'mail'

module Otms
  # private methods for Otms::Api
  module ApiPrivate
    private

    def resource(path)
      RestClient::Resource.new(
        path,
        user_agent: 'OtmsRegressionTesting/0.9',
        verify_ssl: OpenSSL::SSL::VERIFY_NONE)
    end

    def execute_request(path, str, method, type)
      RestClient::Request.execute(
        method: method,
        url: path,
        payload: str,
        headers: { content_type: type },
        user_agent: 'OtmsRegressionTesting/0.9',
        verify_ssl: OpenSSL::SSL::VERIFY_NONE)
    end

    def private_api_key
      # lichaosr
      { login: { demo: 'WewJEnLN',
                 test: 'ZbkFwo7v',
                 dev: 'ZbkFwo7v' },
        password: { demo: 'LdL3por0NGPX0urr',
                    test: 'm1s5AiZxjdaqkPO7',
                    dev: 'm1s5AiZxjdaqkPO7' } }
    end

    def replaced(str, seq)
      seq = seq.to_i == 0 && seq != 0 ? '' : "#{seq}-"
      str.gsub(/2014\d+/, "#{seq}#{Time.new.strftime('%Y%m%d%H%M%S%L')}")
    end

    def activation_mail(start_time, mail_set)
      Mail.defaults { retriever_method :pop3, mail_set }
      loop do
        sleep 3
        @mail = Mail.last
        if @mail.respond_to?('date') && @mail.date.to_time - start_time >= -60
          mails = Mail.find(what: :last, count: 50, order: :desc)
          fine_activation_mail(mails)
          break
        else
          next
        end
      end
      @mail
    end

    def fine_activation_mail(mails)
      return if @mail && @mail.subject.include?('activation')
      mails.each do |m|
        if m.subject.include?('activation')
          @mail = m
          break
        end
      end
    end
  end
end
