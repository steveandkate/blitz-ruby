class Blitz
class Command
class Help < Command # :nodoc:
    def cmd_default argv
        puts
        msg "Usage: blitz <command> <options>"
        helps = [
            { :cmd => 'help', :help => "Display this help" },
            { :cmd => 'account:about', :help => 'Show information about your account' },
            { :cmd => 'api:init', :help => 'Validate and login with your API key' },
            { :cmd => 'couch:fuzz', :help => 'Auto generate blitz tests from CouchDB' },
            { :cmd => 'curl', :help => 'Run a sprint or a rush' },
            { :cmd => 'curl:help', :help => 'Show help on sprint and rushing' },
            { :cmd => 'traceroute', :help => 'Run traceroute remotely' },
            { :cmd => 'traceroute:help', :help => 'Show help on traceroute' },
            { :cmd => 'version', :help => 'Show the version of this Ruby gem' }
        ]
        
        max_cmd_size = helps.inject(0) { |memo, obj| [ obj[:cmd].size, memo ].max } + 4
        helps.each do |h|
            msg "%*s - %s" % [max_cmd_size, h[:cmd], h[:help]]
        end
        puts
    end
end
end # Command
end # Blitz
