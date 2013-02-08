class App
  module Views
    class Index < Layout
      def content
        @content || "Welcome! Mustache lives."
      end
      def logs
      	@logs || "Nothing yet..."
      end
    end
  end
end
