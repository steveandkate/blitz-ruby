class Blitz
class Command
class Version < Command # :nodoc:
    def cmd_default argv
        msg "v#{::Blitz::Version}"
    end
end
end # Command
end # Blitz
