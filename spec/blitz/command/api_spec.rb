require 'spec_helper'

describe Blitz::Command::API do
    before :each do
        @resource = mock RestClient::Resource
        RestClient::Resource.stub!(:new).and_return @resource
        @api = Blitz::Command::API.instance
        @api.credentials= nil
        File.stub!(:exists?).and_return true
        File.stub!(:read).and_return "test@example.com\nabc123"
    end
    
    context "#get_credentials" do
        it "should return given array" do
            @api.credentials= ['abc@example.com', '123456']
            result = @api.get_credentials
            result.should be_nil
            @api.user.should == 'abc@example.com'
            @api.password.should == '123456'
        end
        
        it "should return credentials from the file" do
            result = @api.get_credentials
            result.should_not be_nil
            @api.user.should == 'test@example.com'
            @api.password.should == 'abc123'
        end
    end
    
    context "#client" do
        it "should login using credentials from the file" do
            Blitz::Client.should_receive(:new).
                with('test@example.com', 'abc123', anything)
            result = @api.client
        end
        
        it "should reutn a Blitz::Client instance" do
            result = @api.client
            result.class.should == Blitz::Client
        end
    end
end