class Blitz
class Command
class Traceroute < Command # :nodoc:
    def cmd_help argv
        puts
        msg "Usage: blitz traceroute [-r <region>] host"
        puts
    end

    def cmd_default argv
        args = parse_cli argv
        
        continue = true
        last_index = nil
        begin
            [ 'INT', 'STOP', 'HUP' ].each do |s| 
                trap(s) { continue = false }
            end
            
            job = ::Blitz::Traceroute.queue args
            msg "running from #{yellow(job.region)}..."
            puts
            job.result do |result|
                print_result args, result, last_index
                if not result.hops.empty?
                    last_index = result.hops.size
                end
                sleep 2.0 if not continue
                continue
            end
            puts
            msg "[#{red('aborted')}]" if not continue
        rescue ::Blitz::Traceroute::Error::Region => e
            error "#{yellow(e.region)}: #{red(e.message)}"
        rescue ::Blitz::Traceroute::Error => e
            error red(e.message)
        end
    end
    
    def print_result args, result, last_index
        if last_index and result.hops.size == last_index
            return
        end
        
        result.hops[(last_index || 0)..result.hops.size].each do |hop|
            if hop =~ /!/
                puts red(hop)
            elsif hop =~ /\*/
                puts yellow(hop)
            else
                puts hop
            end
        end
    end
    
    private
    def parse_cli argv
        args = Hash.new
        
        while not argv.empty?
            break if argv.first[0,1] != '-'
            
            k = argv.shift
            if [ '-r', '--region' ].member? k
                args['region'] = shift(k, argv)
                next
            end
            
            raise ArgumentError, "Unknown option #{k}"
        end
            
        if argv.empty?
            raise Test::Unit::AssertionFailedError, "missing host"
        end
        
        args['host'] = argv.shift
        return args
    end
end
end # Command
end # Blitz
