class App
  module Views
    class Index < Layout
      def content
        @content || "Welcome! Mustache lives."
      end
      def logs
      	@logs || "Nothing yet..."
      end
      def backtrace
        @backtrace
      end
      def show_button
        @show_button
      end
      def count
        @count
      end
    end
  end
end
