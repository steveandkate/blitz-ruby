require 'couchrest'

class Blitz
class Command
class Account < Command # :nodoc:
    def cmd_about args
        account = Command::API.client.account_about
        if account['_id'] == 'anonymous'
            error red('Invalid credentials. Use api:init to login first')
            return
        end
        
        puts "email:      #{green(account['profile']['email'])}"
        puts "created_at: #{account['created_at']}"
        puts "updated_at: #{account['created_at']}"
        puts "uuid:       #{yellow(account['uuid'])}"
    end
end
end # Command
end # Blitz
