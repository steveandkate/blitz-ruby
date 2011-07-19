describe "arg parsing" do

    TEST_URL = "http://foo.com"
    VAR = 'foo'
    TEST_VAR_URL = 'http://foo.com?var=#{foo}'
    MIN = 10
    MAX = 30
    # because of 1.8.7 and 1.9.2 differences, maintain both LIST and LIST_AS_STRING constants
    LIST = [ 'a', 'b', 'c', '1', '2', '3']
    LIST_AS_STRING = "[a,b,c,1,2,3]" 
    COUNT = 60
    COUNT_DEFAULT = 1000
    DURATION = 100
    REGION = 'california'

    curl = ::Blitz::Command::Curl.new
    describe "basic args" do

        describe "pattern and region" do
            @args = { 
                "expanded parameters" => [ '--pattern', '1-250:60', "--region", "#{REGION}", "#{TEST_URL}" ],
                "short parameters"    => [ '-p', '1-250:60', "--region", "#{REGION}", "#{TEST_URL}" ]
            }

            @args.each do |name, argv|
                parsed_args = curl.__send__ :parse_cli, argv

                it "should return a hash from the method when sending #{name}" do
                    parsed_args.should be_a(Hash)
                end

                it "should populate the URL into the url key when sending #{name}" do
                    parsed_args['url'].should be_a(String)
                    parsed_args['url'].should == TEST_URL
                end

                it "should put --pattern arguments in the correct structure when sending #{name}" do
                    parsed_args['pattern'].should be_a(Hash)
                    parsed_args['pattern']['iterations'].should be_equal 1
                    parsed_args['pattern']['intervals'].should be_a(Array)
                    parsed_args['pattern']['intervals'][0].should be_a(Hash)
                    parsed_args['pattern']['intervals'][0]['start'].should be_equal 1
                    parsed_args['pattern']['intervals'][0]['end'].should be_equal 250
                    parsed_args['pattern']['intervals'][0]['duration'].should be_equal 60
                end

                it "should allow a specific region to be passed when sending #{name}" do
                    parsed_args['region'].should be_a(String)
                    parsed_args['region'].should == REGION
                end
            end
        end

        @command_args = [ 
            { :short => '-A', :long => '--user-agent', :params => '"TEST STRING"' },
            { :short => '-b', :long => '--cookie', :params => 'name=somecookie' }, 
            { :short => '-d', :long => '--data', :params => '"data for post"'}, 
            { :short => '-D', :long => '--dump-header', :params => '"somefile.out"' },
            { :short => '-e', :long => '--referer', :params => '"http://google.com"' },
            { :short => '-H', :long => '--header', :params => 'some_header' }, 
            { :short => '-s', :long => '--status', :params => '500', :return_type => Integer },
            { :short => '-T', :long => '--timeout', :params => '750', :return_type => Integer }, 
            { :short => '-u', :long => '--user', :params => 'foo:bar' }, 
            { :short => '-X', :long => '--request', :params => 'GET' }, 
            { :short => '-V', :long => '--verbose' }, 
            { :short => '-1', :long => '--tlsv1' }, 
            { :short => '-2', :long => '--sslv2' }, 
            { :short => '-3', :long => '--sslv3' }, 
        ]
        @command_args.each do |test| 
            test_name = /--(.*)/.match(test[:long])[1]
            describe "#{test_name}" do
                [ :short, :long ].each do |flag|
                    argv = []
                    argv << test[flag]
                    argv << test[:params] if test[:params]
                    argv << "#{TEST_URL}"
                    it "#{test[flag]} should not raise an error and populate the hash properly" do
                        lambda { curl.__send__ :parse_cli, argv.dup }.should_not raise_error
                        parsed_args = curl.__send__ :parse_cli, argv
                        # special checks for cookies and headers, as their structure in the return data is different
                        if test_name == 'cookie' || test_name == 'header'
                            return_key = "#{test_name}s"
                            parsed_args[return_key].should be_an(Array)
                            parsed_args[return_key][0].should == test[:params]
                        # special checks for data, as its structure in the return data is different
                        elsif test_name == 'data'
                            parsed_args['content'].should be_a(Hash)
                            parsed_args['content']['data'].should be_an(Array)
                            parsed_args['content']['data'][0].should == test[:params]
                        # special checks for ssl params
                        elsif test_name.match(/^ssl|tls/)
                            parsed_args['ssl'].should == test_name
                        # for integer params, make sure the test returns correct quoting
                        elsif test[:return_type] == Integer
                            parsed_args[test_name].should == test[:params].to_i
                        elsif test[:params].is_a?(String)
                            parsed_args[test_name].should == test[:params]
                        end
                    end
                end
            end
        end
    end

    describe "help" do
        @args = { 
            "expanded parameters" => [ '--help' ],
            "short parameters"    => [ '-h' ]
        }
        @args.each do |name, argv|
            it "should return boolean help flag in hash for #{name}" do
                parsed_args = curl.__send__ :parse_cli, argv
                parsed_args.should be_a(Hash)
                parsed_args['help'].should be_true
            end
        end
    end

    describe "Usage errors" do
        describe "no arguments" do
            it "should throw an error when no arguments are given" do
                lambda { curl.__send__ :parse_cli }.should raise_error(ArgumentError, /wrong number of arg/)
            end
        end
        describe "no URL" do
            @args = { 
                "expanded parameters" => [ '--pattern', '1-250:60', "--variable:#{VAR}", "udid", "--region", "#{REGION}" ],
                "short parameters" => [ '-p', '1-250:60', "-v:#{VAR}", "u", "-r", "#{REGION}" ]
            }
            @args.each do |name, argv|
                it "should throw an error when no URL is given for #{name}" do
                    lambda { curl.__send__ :parse_cli, argv}.should raise_error(ArgumentError, /URL/)
                end
            end
        end
        describe "bad arguments" do
            @args = { 
                "double dash on short param" => [ '--p', '1-250:60', "--variable:#{VAR}", "udid", "--region", "#{REGION}", "#{TEST_URL}" ],
                "single dash on long param" => [ '-pattern', '1-250:60', "-v:#{VAR}", "u", "-r", "#{REGION}", "#{TEST_URL}" ],
                "unsupported option, short format" => [ '-z', "#{TEST_URL}" ],
                "unsupported option, long format" => [ '--foobar', "#{TEST_URL}" ]
            }
            @args.each do |name, argv|
                it "should throw an error when bad arguments are passed for #{name}" do
                    lambda { curl.__send__ :parse_cli, argv}.should raise_error(ArgumentError, /Unknown option/)
                end
            end
        end
    end

    describe "variable support" do
        describe "number and alpha" do
            @args = { 
                "number, expanded parameters, no values given" => 
                    [ '--pattern', '1-250:60', "--variable:#{VAR}", "number", "--region", "#{REGION}", "#{TEST_VAR_URL}" ],
                "number, short parameters, no values given" => 
                    [ '-p', '1-250:60', "-v:#{VAR}", "n", "--region", "#{REGION}", "#{TEST_VAR_URL}" ],
                "number, expanded parameters, no count given" =>
                    [ '--pattern', '1-250:60', "--variable:#{VAR}", "number[#{MIN},#{MAX}]", "--region", "#{REGION}", "#{TEST_VAR_URL}" ],
                "number, short parameters, no count given" => 
                    [ '-p', '1-250:60', "-v:#{VAR}", "n[#{MIN},#{MAX}]", "--region", "#{REGION}", "#{TEST_VAR_URL}" ],
                "number, expanded parameters, count given" =>
                    [ '--pattern', '1-250:60', "--variable:#{VAR}", "number[#{MIN},#{MAX},#{COUNT}]", "--region", "#{REGION}", "#{TEST_VAR_URL}" ],
                "number, short parameters, count given" => 
                    [ '-p', '1-250:60', "-v:#{VAR}", "n[#{MIN},#{MAX},#{COUNT}]", "--region", "#{REGION}", "#{TEST_VAR_URL}" ],
                "alpha, expanded parameters, no values given" => 
                    [ '--pattern', '1-250:60', "--variable:#{VAR}", "alpha", "--region", "#{REGION}", "#{TEST_VAR_URL}" ],
                "alpha, short parameters, no values given" => 
                    [ '-p', '1-250:60', "-v:#{VAR}", "a", "--region", "#{REGION}", "#{TEST_VAR_URL}" ],
                "alpha, expanded parameters, no count given" =>
                    [ '--pattern', '1-250:60', "--variable:#{VAR}", "alpha[#{MIN},#{MAX}]", "--region", "#{REGION}", "#{TEST_VAR_URL}" ],
                "alpha, short parameters, no count given" => 
                    [ '-p', '1-250:60', "-v:#{VAR}", "a[#{MIN},#{MAX}]", "--region", "#{REGION}", "#{TEST_VAR_URL}" ],
                "alpha, expanded parameters, count given" =>
                    [ '--pattern', '1-250:60', "--variable:#{VAR}", "alpha[#{MIN},#{MAX},#{COUNT}]", "--region", "#{REGION}", "#{TEST_VAR_URL}" ],
                "alpha, short parameters, count given" => 
                    [ '-p', '1-250:60', "-v:#{VAR}", "a[#{MIN},#{MAX},#{COUNT}]", "--region", "#{REGION}", "#{TEST_VAR_URL}" ]
            }

            @args.each do |name, argv|
                parsed_args = curl.__send__ :parse_cli, argv
                it "should work with #{name}" do
                    parsed_args['variables'].should be_a(Hash)
                    parsed_args['variables'][VAR].should be_a(Hash)

                    if name.match(/^number/)
                        parsed_args['variables'][VAR]['type'].should == "number"
                    elsif name.match(/^alpha/)
                        parsed_args['variables'][VAR]['type'].should == "alpha"
                    end

                    if name.match(/no values given/)
                        parsed_args['variables'][VAR]['min'].should be_nil
                        parsed_args['variables'][VAR]['max'].should be_nil
                        parsed_args['variables'][VAR]['count'].should be_nil
                    elsif name.match(/no count given/)
                        parsed_args['variables'][VAR]['min'].should be_an(Integer)
                        parsed_args['variables'][VAR]['min'].should == MIN
                        parsed_args['variables'][VAR]['max'].should be_an(Integer)
                        parsed_args['variables'][VAR]['max'].should == MAX
                        parsed_args['variables'][VAR]['count'].should be_an(Integer)
                        parsed_args['variables'][VAR]['count'].should == COUNT_DEFAULT
                    else
                        parsed_args['variables'][VAR]['min'].should be_an(Integer)
                        parsed_args['variables'][VAR]['min'].should == MIN
                        parsed_args['variables'][VAR]['max'].should be_an(Integer)
                        parsed_args['variables'][VAR]['max'].should == MAX
                        parsed_args['variables'][VAR]['count'].should be_an(Integer)
                        parsed_args['variables'][VAR]['count'].should == COUNT
                    end

                end
            end
        end

        describe "list parameter" do
            @args = { 
                "expanded parameters" => [ '--pattern', '1-250:60', "--variable:#{VAR}", "list#{LIST_AS_STRING}", "--region", "#{REGION}", "#{TEST_URL}" ],
                "short parameters" => [ '-p', '1-250:60', "-v:#{VAR}", "#{LIST_AS_STRING}", "-r", "#{REGION}", "#{TEST_URL}" ]
            }
            @args.each do |name, argv|
                it "should allow lists to be sent as a variable type for #{name}" do
                    parsed_args = curl.__send__ :parse_cli, argv
                    parsed_args['variables'][VAR].should be_a(Hash)
                    parsed_args['variables'][VAR]['type'].should == 'list'
                    parsed_args['variables'][VAR]['entries'].should be_an(Array)
                    parsed_args['variables'][VAR]['entries'].should == LIST
                end
            end
        end

        describe "udid parameter" do
            @args = { 
                "expanded parameters" => [ '--pattern', '1-250:60', "--variable:#{VAR}", "udid", "--region", "#{REGION}", "#{TEST_URL}" ],
                "short parameters" => [ '-p', '1-250:60', "-v:#{VAR}", "u", "-r", "#{REGION}", "#{TEST_URL}" ]
            }
            @args.each do |name, argv|
                parsed_args = curl.__send__ :parse_cli, argv
                it "should allow udid to be sent as a variable type" do
                    parsed_args['variables'][VAR].should be_a(Hash)
                    parsed_args['variables'][VAR]['type'].should == 'udid'
                end
            end
        end
    end
end 

