class App
  module Views
    class Layout < Mustache
      def title 
        @title || "PHP Error Log Analyzer"
      end
    end
  end
end
