class Blitz
class Traceroute
    class Result
        # The region from which the traceroute was executed
        attr_reader :region
        
        # The timeline of the rush containing various statistics.
        attr_reader :hops
        
        def initialize json # :nodoc:
            result = json['result']
            @region = result['region']
            @hops = result['hops']
        end        
    end
    
    def self.execute args
        self.queue(args).result
    end
    
    def self.queue args # :nodoc:
        res = Command::API.client.traceroute_execute args
        raise Error.new(res) if res['error']
        return self.new res
    end
    
    attr_reader :job_id # :nodoc:
    attr_reader :region # :nodoc:
    
    def initialize json # :nodoc:
        @job_id = json['job_id']
        @region = json['region']
    end
    
    def result &block # :nodoc:
        last = nil
        while true
            sleep 2.0

            job = Command::API.client.job_status job_id
            if job['error']
                raise Error
            end
            
            result = job['result']
            next if job['status'] == 'queued'
            next if job['status'] == 'running' and not result

            raise Error if not result

            error = result['error']
            if error
                if error == 'dns'
                    raise Error::DNS.new(result)
                elsif error == 'parse'
                    raise Error::Parse.new(result)
                else
                    raise Error
                end
            end
            
            last = Result.new(job)
            continue = yield last rescue false
            if continue == false
                abort!
                break
            end
            
            break if job['status'] == 'completed'
        end
        
        return last
    end
    
    def abort! # :nodoc:
        Command::API.client.abort_job job_id rescue nil
    end    
end
end # blitz