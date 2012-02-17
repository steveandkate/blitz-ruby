require 'spec_helper'

describe Blitz::Command::Curl do
    
    let(:sprint_data)  { 
            {
                'line'=>"GET / HTTP/1.1", 
                'method'=>"GET", 
                'url'=>"www.example.com", 
                'content'=>"",
                'status'=>200, 
                'message'=>"OK", 
                'headers'=> {
                    "User-Agent"=>"blitz.io; 5f691b@11.22.33.250", 
                    "Host"=>"blitz.io", 
                    "X-Powered-By"=>"blitz.io", 
                    "X-User-ID"=>"5f6938a60e", 
                    "X-User-IP"=>"44.55.66.250"
                }
            }
         }
    
    def mocked_sprint_request
        Blitz::Curl::Sprint::Request.new(sprint_data)
    end
    
    def mocked_sprint_args
        {
            "steps"=>[{"url"=>"http://blitz.io"}], 
            "region"=>"california", 
            "dump-header"=>"/mocked/path/head.txt", 
            "verbose"=>true
        }
    end
    
    def mocked_sprint
        sprint = {
         'result' => {
             'region'=>"california", 
             'duration'=> 0.39443,
             'steps'=>[
                  'connect'=>0.117957, 
                  'duration'=>0.394431, 
                  'request' => sprint_data,
                  'response' => sprint_data
              ]  
         } 
        }
        Blitz::Curl::Sprint::Result.new(sprint)
    end
    
    context "#print_sprint_header_to_file" do
        it "should warn user if it can not open the file" do
            obj = Blitz::Command::Curl.new
            File.should_receive(:open).with("path", "a").and_raise("No such file or directory - path")
            obj.should_receive(:puts).with("\e[31mNo such file or directory - path\e[0m")
            obj.send(:print_sprint_header_to_file, "path", "request")
        end        
        it "should print request headers to file" do
            file = mock('file')
            request = mocked_sprint_request
            obj = Blitz::Command::Curl.new
            File.should_receive(:open).with("path", "a").and_yield(file)
            file.should_receive(:puts).with("")
            file.should_receive(:puts).with("GET / HTTP/1.1")
            file.should_receive(:puts).with("User-Agent: blitz.io; 5f691b@11.22.33.250")
            file.should_receive(:puts).with("Host: blitz.io")
            file.should_receive(:puts).with("X-Powered-By: blitz.io")
            file.should_receive(:puts).with("X-User-ID: 5f6938a60e")
            file.should_receive(:puts).with("X-User-IP: 44.55.66.250")
            obj.send(:print_sprint_header_to_file, "path", request)
        end
    end
    
    context "#print_sprint_header" do
        def check_print_sprint_header path="/mocked/path/head.txt"
            myfile = StringIO.new
            request = mocked_sprint_request
            symbol = "> "
            obj = Blitz::Command::Curl.new
            yield(obj, myfile, path)
            obj.send(:print_sprint_header, request, path, symbol)
        end
        it "should prints header to console when path is '-'" do
            check_print_sprint_header("-") {|obj, myfile, path|
                obj.should_receive(:puts).with("> GET / HTTP/1.1")
                obj.should_receive(:puts).with("> User-Agent: blitz.io; 5f691b@11.22.33.250\r\n")
                obj.should_receive(:puts).with("> Host: blitz.io\r\n")
                obj.should_receive(:puts).with("> X-Powered-By: blitz.io\r\n")
                obj.should_receive(:puts).with("> X-User-ID: 5f6938a60e\r\n")
                obj.should_receive(:puts).with("> X-User-IP: 44.55.66.250\r\n")
                obj.should_receive(:puts).with()
            }
        end
        it "should prints header to file when path is not '-'" do
            check_print_sprint_header {|obj, myfile, path|
                obj.should_receive(:print_sprint_header_to_file).and_return(true)
            }
        end
    end
    
    context "#print_sprint_result" do
        def check_print_sprint_result args
            result = mocked_sprint
            obj = Blitz::Command::Curl.new
            yield(obj, result)
            obj.send(:print_sprint_result, args, result)
        end
        it "should not dump-header and verbose when they are not available" do
            args = mocked_sprint_args
            args.delete "verbose"
            args.delete "dump-header"
            check_print_sprint_result(args){|obj, result|
                obj.should_receive(:puts).with("Transaction time \e[32m394 ms\e[0m")
                obj.should_receive(:puts).with()
                obj.should_receive(:puts).with("> GET www.example.com")
                obj.should_receive(:puts).with("< 200 OK in \e[32m394 ms\e[0m")
                obj.should_receive(:puts).with()
            }
        end
        it "should dump-header and verbose when both are available" do
            check_print_sprint_result(mocked_sprint_args){|obj, result|
                obj.should_receive(:print_sprint_header).twice.and_return(true)
                obj.should_receive(:print_sprint_content).twice.and_return(true)
                result.should_receive(:respond_to?).with(:duration).and_return(false)
            }
        end
        it "should only do verbose when dump-header is not available" do
            args = mocked_sprint_args
            args.delete "dump-header"
            check_print_sprint_result(args){|obj, result|
                obj.should_not_receive(:print_sprint_header)
                obj.should_receive(:print_sprint_content).twice.and_return(true)
                result.should_receive(:respond_to?).with(:duration).and_return(false)
            }
        end
        it "should only do dump-header when verbose is not available" do
            args = mocked_sprint_args
            args.delete "verbose"
            check_print_sprint_result(args){|obj, result|
                obj.should_receive(:print_sprint_header).twice.and_return(true)
                obj.should_not_receive(:print_sprint_content)
                result.should_receive(:respond_to?).with(:duration).and_return(false)
            }
        end
    end
    
end