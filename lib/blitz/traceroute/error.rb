class Blitz
class Traceroute
class Error < StandardError # :nodoc:
    def initialize json={}
        super json['reason'] || "Hmmm, something went wrong. Try again in a little bit?"
    end
    
    # The base class for all exceptions thrown by the distributed engines
    class Region < Error
        # The region from which the test was run
        attr_reader :region
        
        def initialize json # :nodoc:
            @region = json['region']
            super
        end
    end
    
    # This exception is raised when the DNS resolution fails
    class DNS < Region
    end
    
    # This exception is raised when the arguments to traceroute are invalid
    class Parse < Region
    end    
end
end # Traceroute
end # Blitz
