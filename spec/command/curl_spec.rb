describe "command args" do

    TEST_URL = "http://foo.com"
    VAR = 'foo'
    TEST_VAR_URL = 'http://foo.com?var=#{foo}'
    MIN = 10
    MAX = 30
    COUNT = 60
    COUNT_DEFAULT = 1000
    DURATION = 100
    REGION = 'california'

    before :each do
    end
    
    after :each do
    end

=begin
    
    Usage: blitz curl <options> <url>

    --user-agent  -A <string>      User-Agent to send to server
    --cookie      -b name=<string> Cookie to send to the server (multiple)
    --data        -d <string>      Data to send in a PUT or POST request
    --dump-header -D <file>        Print the request/response headers
    --referer     -e <string>      Referer URL
    --help        -h               Help on command line options
    --header      -H <string>      Custom header to pass to server
    --pattern     -p <s>-<e>:<d>   Ramp from s to e concurrent requests in d secs
    --region      -r <string>      california|virginia|singapore|ireland|japan
    --status      -s <number>      Assert on the HTTP response status code
    --timeout     -T <ms>          Wait time for both connect and responses
    --user        -u <user[:pass]> User and password for authentication
    --request     -X <string>      Request method to use (GET, HEAD, PUT, etc.)
    --variable    -v <string>      Define a variable to use
    --verbose     -V               Print the request/response headers
    --tlsv1       -1               Use TLSv1 (SSL)
    --sslv2       -2               Use SSLv2 (SSL)
    --sslv3       -3               Use SSLv3 (SSL)
=end

    describe "curl command argument parsing" do    

        curl = ::Blitz::Command::Curl.new

        describe "basic command arg requirements" do
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
                    it "should allow variable passing with #{name}" do
                        parsed_args['variables'].should be_a(Hash)
                        parsed_args['variables'][VAR].should be_a(Hash)
                    end
                    it "should populate the curl API hash correctly for #{name}" do
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

            describe "bad variables" do
                it "should not allow improperly formatted variables to be passed to curl" do
                    pending "Have not written the unhappy path test cases yet"
                end
            end
        end
    end 
end 

