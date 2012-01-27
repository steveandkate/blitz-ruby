require 'spec_helper'

describe Blitz::Client do
    before :each do
        @resource = mock RestClient::Resource
        RestClient::Resource.stub!(:new).and_return @resource
        @client = Blitz::Client.new "test@example.com", '123456'
    end
    
    after :each do
        RestClient::Resource.unstub!(:new)
    end
    
    context "#login" do
        before :each do
            @resource.should_receive(:[]).with('/login/api').and_return @resource
            @resource.should_receive(:get).and_return "{\"api_key\":\"abc123\"}"
        end
        
        it "should return an api_key" do
            result = @client.login
            result.should_not be_nil
            result['api_key'].should == 'abc123'
        end
    end
    
    context "#account_about" do
        before :each do
            json = "{\"api_key\":\"abc123\", \"profile\":{\"email\":\"test@example.com\"}}"
            @resource.should_receive(:[]).with('/api/1/account/about').and_return @resource
            @resource.should_receive(:get).and_return json
        end
        
        it "should return a profile" do
            result = @client.account_about
            result.should_not be_nil
            result['profile'].should_not be_nil
            result['profile']['email'].should == "test@example.com"
        end
    end
    
    context "#curl_execute" do
        before :each do
            json = "{\"ok\":true, \"job_id\":\"j123\", \"status\":\"queued\"}"
            @resource.should_receive(:[]).with('/api/1/curl/execute').and_return @resource
            @resource.should_receive(:post).and_return json
        end
        
        it "should return a profile" do
            result = @client.curl_execute "{\"url\":\"wwwexample.com\"}"
            result.should_not be_nil
            result['ok'].should be_true
            result['status'].should == "queued"
        end
        
    end
end