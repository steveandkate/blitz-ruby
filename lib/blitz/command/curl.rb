class Blitz
class Command
class Curl < Command # :nodoc:
    include Term::ANSIColor
    
    def cmd_help argv
        help
    end

    def cmd_run argv
        args = parse_cli argv
        if args['help']
            return help
        end

        if not args['pattern']
            sprint args
            return
        else
            rush args
        end
    end
    
    alias_method :cmd_default, :cmd_run

    private
    def authorize_error e
        base_url = "#{e.scheme}://#{e.host}:#{e.port}"
        puts
        error "You haven't verified that you are the devops dude for #{e.host}. Make"
        error "sure the following URL is reachable and returns the string '42'."
        error ""
        error "#{base_url}/#{e.uuid}"
        error ""
        if e.checks
            error "We tried checking the following URLs and got this"
            error ""
            e.checks.each do |check|
                bytes = ''
                if check['bytes']
                    bytes = '| ' + check['bytes']
                end
                error "#{bold(red(check['code']))} | #{cyan(check['url'])} #{bytes}"
            end
            error ''
        end
        error "If your app is RESTfully built with sinatra or rails, simply add this route:"
        error ""
        error "get '/#{cyan(e.uuid)}' do"
        error "    '42'"
        error "end"
        error ""
        error "Once this is done, you can blitz #{cyan(e.host)} all you want."
        puts
    end

    def sprint args
        begin
            job = ::Blitz::Curl::Sprint.queue args
            result = job.result
            print_sprint_result args, result
        rescue ::Blitz::Curl::Error::Authorize => e
            authorize_error e
        rescue ::Blitz::Curl::Error::Step => e
            error "#{yellow(e.region)}: #{red(e.message)} in step #{e.step}"
            puts
            print_sprint_result args, e
        rescue ::Blitz::Curl::Error::Region => e
            error = "#{yellow(e.region)}: #{red(e.message)}"
        rescue ::Blitz::Curl::Error => e
            error red(e.message)
        end
    end
    
    def pretty_print_duration duration
        rtt = duration
		if rtt < 1.0
			rtt = (rtt * 1000).floor.to_s + ' ms';
		else
			rtt = ("%.2f" % rtt) + ' sec';
		end
    end

    def print_sprint_result args, result
        if result.respond_to? :duration
            rtt = pretty_print_duration result.duration
            msg "#{yellow(result.region)}: Transaction time #{green(rtt)}"
            puts
        end
        
        result.steps.each do |step|
            req, res = step.request, step.response
            if args['dump-header'] or args['verbose']
                puts "> " + req.line
                req.headers.each_pair { |k, v| puts "> #{k}: #{v}\r\n" }
                puts

                content = req.content
                if not content.empty?
                    if /^[[:print:]]+$/ =~ content
                        puts content
                    else
                        puts Hexy.new(content).to_s
                    end
                    puts
                end

                puts "< " + res.line
                res.headers.each_pair { |k, v| puts "< #{k}: #{v}\r\n" }
                puts
                content = res.content
                if not content.empty?
                    if /^[[:print:]]+$/ =~ content
                        puts content
                    else
                        puts Hexy.new(content).to_s
                    end
                end                
            else
                puts "> " + req.method + ' ' + req.url
                if res
                    text = "< " + res.status.to_s + ' ' + res.message
                    if step.duration
                        text << ' in ' + green(pretty_print_duration(step.duration))
                    end
                    puts text
                end
                puts
            end
        end
    end

    def rush args
        continue = true
        last_index = nil
        begin
            [ 'INT', 'STOP', 'HUP' ].each do |s| 
                trap(s) { continue = false }
            end
            job = ::Blitz::Curl::Rush.queue args
            msg "rushing from #{yellow(job.region)}..."
            puts
            job.result do |result|
                print_rush_result args, result, last_index
                if not result.timeline.empty?
                    last_index = result.timeline.size
                end
                sleep 2.0 if not continue
                continue
            end
            puts
            msg "[#{red('aborted')}]" if not continue
        rescue ::Blitz::Curl::Error::Authorize => e
            authorize_error e
        rescue ::Blitz::Curl::Error::Region => e
            error "#{yellow(e.region)}: #{red(e.message)}"
        rescue ::Blitz::Curl::Error => e
            error red(e.message)
        end
    end
    
    def print_rush_result args, result, last_index
        if last_index.nil?
            print yellow("%6s " % "Time")
            print "%6s " % "Users"
            print green("%8s " % "Hits")
            print magenta("%8s " % "Timeouts")
            print red("%8s " % "Errors")
            print green("%8s " % "Hits/s")
            print "%s" % "Mbps"
            puts
        end
        
        if last_index and result.timeline.size == last_index
            return
        end
        
        last = result.timeline[-2]
        curr = result.timeline[-1]
        print yellow("%5.1fs " % curr.timestamp)
        print "%6d " % curr.volume
        print green("%8d " % curr.hits)
        print magenta("%8d " % curr.timeouts)
        print red("%8d " % curr.errors)
        
        if last
            elapsed = curr.timestamp - last.timestamp
            mbps = ((curr.txbytes + curr.rxbytes) - (last.txbytes + last.rxbytes))/elapsed/1024.0/1024.0
            htps = (curr.hits - last.hits)/elapsed
            print green(" %7.2f " % htps)
            print "%.2f" % mbps
        end
        
        print "\n"
    end

    def help
        helps = [
            { :short => '-A', :long => '--user-agent', :value => '<string>', :help => 'User-Agent to send to server' },
            { :short => '-b', :long => '--cookie', :value => 'name=<string>', :help => 'Cookie to send to the server (multiple)' },
            { :short => '-d', :long => '--data', :value => '<string>', :help => 'Data to send in a PUT or POST request' },
            { :short => '-D', :long => '--dump-header', :value => '<file>', :help => 'Print the request/response headers' },
            { :short => '-e', :long => '--referer', :value => '<string>', :help => 'Referer URL' },
            { :short => '-h', :long => '--help', :value => '', :help => 'Help on command line options' },
            { :short => '-H', :long => '--header', :value => '<string>', :help => 'Custom header to pass to server' },
            { :short => '-p', :long => '--pattern', :value => '<s>-<e>:<d>', :help => 'Ramp from s to e concurrent requests in d secs' },
            { :short => '-r', :long => '--region', :value => '<string>', :help => 'california|virginia|singapore|ireland|japan' },
            { :short => '-s', :long => '--status', :value => '<number>', :help => 'Assert on the HTTP response status code' },
            { :short => '-T', :long => '--timeout', :value => '<ms>', :help => 'Wait time for both connect and responses' },
            { :short => '-u', :long => '--user', :value => '<user[:pass]>', :help => 'User and password for authentication' },
            { :short => '-X', :long => '--request', :value => '<string>', :help => 'Request method to use (GET, HEAD, PUT, etc.)' },
            { :short => '-v', :long => '--variable', :value => '<string>', :help => 'Define a variable to use' },
            { :short => '-V', :long => '--verbose', :value => '', :help => 'Print the request/response headers' },
            { :short => '-1', :long => '--tlsv1', :value => '', :help => 'Use TLSv1 (SSL)' },
            { :short => '-2', :long => '--sslv2', :value => '', :help => 'Use SSLv2 (SSL)' },
            { :short => '-3', :long => '--sslv3', :value => '', :help => 'Use SSLv3 (SSL)' }
        ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        msg "Usage: blitz curl <options> <url>"
        puts
        helps.each do |h|
            msg "%-*s %*s %-*s %s" % [max_long_size, h[:long], 2, h[:short], max_value_size, h[:value], h[:help]]
        end
        puts
    end

    def parse_cli argv
        hash = { 'steps' => [] }
        
        while not argv.empty?
            hash['steps'] << Hash.new
            step = hash['steps'].last
            
            while not argv.empty?
                break if argv.first[0,1] != '-'

                k = argv.shift
                if [ '-A', '--user-agent' ].member? k
                    step['user-agent'] = shift(k, argv)
                    next
                end

                if [ '-b', '--cookie' ].member? k
                    step['cookies'] ||= []
                    step['cookies'] << shift(k, argv)
                    next
                end

                if [ '-d', '--data' ].member? k
                    step['content'] ||= Hash.new
                    step['content']['data'] ||= []
                    v = shift(k, argv)
                    v = File.read v[1..-1] if v =~ /^@/
                    step['content']['data'] << v
                    next
                end

                if [ '-D', '--dump-header' ].member? k
                    hash['dump-header'] = shift(k, argv)
                    next
                end

                if [ '-e', '--referer'].member? k
                    step['referer'] = shift(k, argv)
                    next
                end

                if [ '-h', '--help' ].member? k
                    hash['help'] = true
                    next
                end

                if [ '-H', '--header' ].member? k
                    step['headers'] ||= []
                    step['headers'].push shift(k, argv)
                    next
                end

                if [ '-p', '--pattern' ].member? k
                    v = shift(k, argv)
                    v.split(',').each do |vt|
                        unless /^(\d+)-(\d+):(\d+)$/ =~ vt
                            raise Test::Unit::AssertionFailedError, "invalid ramp pattern"
                        end
                        hash['pattern'] ||= { 'iterations' => 1, 'intervals' => [] }
                        hash['pattern']['intervals'] << {
                            'iterations' => 1,
                            'start' => $1.to_i,
                            'end' => $2.to_i,
                            'duration' => $3.to_i
                        }
                    end
                    next
                end

                if [ '-r', '--region' ].member? k
                    v = shift(k, argv)
                    assert_match(/^california|virginia|singapore|ireland|japan$/, v, 'region must be one of california, virginia, singapore, japan or ireland')
                    hash['region'] = v
                    next
                end

                if [ '-s', '--status' ].member? k
                    step['status'] = shift(k, argv).to_i
                    next
                end

                if [ '-T', '--timeout' ].member? k
                    step['timeout'] = shift(k, argv).to_i
                    next
                end

                if [ '-u', '--user' ].member? k
                    step['user'] = shift(k, argv)
                    next
                end

                if [ '-X', '--request' ].member? k
                    step['request'] = shift(k, argv)
                    next
                end
            
                if /-v:(\S+)/ =~ k or /--variable:(\S+)/ =~ k 
                    vname = $1
                    vargs = shift(k, argv)

                    assert_match /^[a-zA-Z][a-zA-Z0-9]*$/, vname, "variable name must be alphanumeric: #{vname}"

                    step['variables'] ||= Hash.new
                    vhash = step['variables'][vname] = Hash.new
                    if vargs.match /^(list)?\[([^\]]+)\]$/
                        vhash['type'] = 'list'
                        vhash['entries'] = $2.split(',')
                    elsif vargs.match /^(a|alpha)$/
                        vhash['type'] = 'alpha'
                    elsif vargs.match /^(a|alpha)\[(\d+),(\d+)(,(\d+))??\]$/
                        vhash['type'] = 'alpha'
                        vhash['min'] = $2.to_i
                        vhash['max'] = $3.to_i
                        vhash['count'] = $5 ? $5.to_i : 1000
                    elsif vargs.match /^(n|number)$/
                        vhash['type'] = 'number'
                    elsif vargs.match /^(n|number)\[(-?\d+),(-?\d+)(,(\d+))?\]$/
                        vhash['type'] = 'number'
                        vhash['min'] = $2.to_i
                        vhash['max'] = $3.to_i
                        vhash['count'] = $5 ? $5.to_i : 1000
                    elsif vargs.match /^(u|udid)$/
                        vhash['type'] = 'udid'
                    else
                        raise ArgumentError, "Invalid variable args for #{vname}: #{vargs}"
                    end
                    next
                end

                if [ '-V', '--verbose' ].member? k
                    hash['verbose'] = true
                    next
                end

                if [ '-1', '--tlsv1' ].member? k
                    step['ssl'] = 'tlsv1'
                    next
                end

                if [ '-2', '--sslv2' ].member? k
                    step['ssl'] = 'sslv2'
                    next
                end

                if [ '-3', '--sslv3' ].member? k
                    step['ssl'] = 'sslv3'
                    next
                end

                raise ArgumentError, "Unknown option #{k}"
            end

            if step.member? 'content'
                data_size = step['content']['data'].inject(0) { |m, v| m + v.size }
                assert(data_size < 10*1024, "POST content must be < 10K")
            end
            
            break if hash['help']
            
            url = argv.shift
            raise ArgumentError, "no URL specified!" if not url
            step['url'] = url
        end
        
        if not hash['help']
            if hash['steps'].empty?
                raise ArgumentError, "no URL specified!"
            end
        end

        hash
    end

    def shift key, argv
        val = argv.shift
        assert_not_nil(val, "missing value for #{key}")
        val
    end
end # Curl
end # Command
end # Blitz
