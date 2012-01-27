require 'spec_helper'

describe Blitz::Curl::Rush do
    before :each do
        @resource = mock RestClient::Resource
        RestClient::Resource.stub!(:new).and_return @resource
        File.stub!(:exists?).and_return true
        File.stub!(:read).and_return "test@example.com\nabc123"
        args = {
            :region => 'california',
            :steps => [ { :url => "http://www.example.com"}],
            :pattern => {
               :intervals => [{ :start => 1, :end => 10000, :duration => 60 }]
           }
        }
        @rush = Blitz::Curl::Rush.new args
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
            @rush.region.should be_nil
            @rush.queue
            @rush.region.should == 'california'
        end

        it "should set the job_id" do
            @rush.job_id.should be_nil
            @rush.queue
            @rush.job_id.should == 'j123'
        end
    end
    
    context "#result" do
        before :each do
            @queue = mock RestClient::Resource
            json = "{\"ok\":true, \"job_id\":\"j123\", \"status\":\"queued\", \"region\":\"california\"}"
            @resource.should_receive(:[]).with('/api/1/curl/execute').and_return @queue
            @queue.should_receive(:post).and_return json
            @status = mock RestClient::Resource
            json2 = "{\"ok\":true, \"status\":\"completed\", \"result\":{\"region\":\"california\", \"timeline\":[]}}"
            @resource.should_receive(:[]).with("/api/1/jobs/j123/status").and_return @status
            @status.should_receive(:get).and_return json2
            @rush.queue
        end
        
        it "should return a new Blitz::Curl::Rush::Result instance" do
            result = @rush.result
            result.should_not be_nil
            result.class.should == Blitz::Curl::Rush::Result
        end
        
        it "should return result with region california" do
            result = @rush.result
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
            json2 = "{\"ok\":true, \"status\":\"completed\", \"result\":{\"region\":\"california\", \"timeline\":[]}}"
            @resource.should_receive(:[]).with("/api/1/jobs/j123/status").and_return @status
            @status.should_receive(:get).and_return json2
        end
        
        it "should return a new Blitz::Curl::Rush::Result instance" do
            result = @rush.execute
            result.should_not be_nil
            result.class.should == Blitz::Curl::Rush::Result
        end
        
        it "should return result with region california" do
            result = @rush.execute
            result.region.should == 'california'
        end
    end
end