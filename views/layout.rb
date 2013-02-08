class App
  module Views
    class Layout < Mustache
      def title 
        @title || "Social Devel -- Be more social"
      end
    end
  end
end
