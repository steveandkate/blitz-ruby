require 'spec_helper'

describe Blitz::Curl::Sprint do
    before :each do
        @resource = mock RestClient::Resource
        RestClient::Resource.stub!(:new).and_return @resource
        File.stub!(:exists?).and_return true
        File.stub!(:read).and_return "test@example.com\nabc123"
        args = {
            :region => 'california',
            :steps => [ { :url => "http://www.example.com"}]
        }
        @sprint = Blitz::Curl::Sprint.new args
    end
    
    context "#queue" do
        before :each do
            @queue = mock RestClient::Resource
            json = "{\"ok\":true, \"job_id\":\"j123\", \"status\":\"queued\", \"region\":\"california\"}"
            @resource.should_receive(:[]).with('/api/1/curl/execute').and_return @queue
            @queue.should_receive(:post).and_return json
            @status = mock RestClient::Resource
        end
        
        it "should set the region" do
            @sprint.region.should be_nil
            @sprint.queue
            @sprint.region.should == 'california'
        end

        it "should set the job_id" do
            @sprint.job_id.should be_nil
            @sprint.queue
            @sprint.job_id.should == 'j123'
        end
    end
    
    context "#result" do
        before :each do
            @queue = mock RestClient::Resource
            json = "{\"ok\":true, \"job_id\":\"j123\", \"status\":\"queued\", \"region\":\"california\"}"
            @resource.should_receive(:[]).with('/api/1/curl/execute').and_return @queue
            @queue.should_receive(:post).and_return json
            @status = mock RestClient::Resource
            json2 = "{\"ok\":true, \"status\":\"completed\", \"result\":{\"region\":\"california\", \"steps\":[]}}"
            @resource.should_receive(:[]).with("/api/1/jobs/j123/status").and_return @status
            @status.should_receive(:get).and_return json2
            @sprint.queue
        end
        
        it "should return a new Blitz::Curl::Sprint::Result instance" do
            result = @sprint.result
            result.should_not be_nil
            result.class.should == Blitz::Curl::Sprint::Result
        end
        
        it "should return result with region california" do
            result = @sprint.result
            result.region.should == 'california'
        end
    end
    
    context "#execute" do
        before :each do
            @queue = mock RestClient::Resource
            json = "{\"ok\":true, \"job_id\":\"j123\", \"status\":\"queued\", \"region\":\"california\"}"
            @resource.should_receive(:[]).with('/api/1/curl/execute').and_return @queue
            @queue.should_receive(:post).and_return json
            @status = mock RestClient::Resource
            json2 = "{\"ok\":true, \"status\":\"completed\", \"result\":{\"region\":\"california\", \"steps\":[]}}"
            @resource.should_receive(:[]).with("/api/1/jobs/j123/status").and_return @status
            @status.should_receive(:get).and_return json2
        end
        
        it "should return a new Blitz::Curl::Sprint::Result instance" do
            result = @sprint.execute
            result.should_not be_nil
            result.class.should == Blitz::Curl::Sprint::Result
        end
        
        it "should return result with region california" do
            result = @sprint.execute
            result.region.should == 'california'
        end
    end
end