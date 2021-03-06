require 'json'

class Blitz
class Client # :nodoc:
    attr_reader :blitz
    
    def initialize user, apik, host='blitz.io'
        scheme = host.index('localhost') ? 'http' : 'https'
        @blitz = RestClient::Resource.new "#{scheme}://#{host}", \
            :headers => {
                :x_api_user => user,
                :x_api_key => apik,
                :x_api_client => 'gem'
            }
    end
    
    def login
        JSON.parse blitz['/login/api'].get
    end
    
    def account_about
        JSON.parse blitz['/api/1/account/about'].get
    end
    
    def curl_execute data
        JSON.parse blitz['/api/1/curl/execute'].post(data.to_json)
    end
    
    def traceroute_execute data
        JSON.parse blitz['/api/1/traceroute/execute'].post(data.to_json)
    end
    
    def job_status job_id
        JSON.parse blitz["/api/1/jobs/#{job_id}/status"].get
    end
    
    def abort_job job_id
        JSON.parse blitz["/api/1/jobs/#{job_id}/abort"].put ''
    end
end
end
