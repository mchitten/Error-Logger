
module AppSetup
  # @Config\path("/ab")
  class FacebookApps
  register Mustache::Sinatra

     # @Config\path("/blah")
     def blahAction()
        @content = "Ahhhh"
        mustache :index
     end

     # @Config\path("/nooo")
     def noAction()
        @content = "Nooooo"
        mustache :index
     end
  end
end
