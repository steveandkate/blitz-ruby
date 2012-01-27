require 'blitz/utils'

class Blitz
class Command # :nodoc:
    include Helper
    include Term::ANSIColor
    include Blitz::Utils
end
end # Blitz

Dir["#{File.dirname(__FILE__)}/command/*.rb"].each { |c| require c }
