class App
  module Views
    class MorePosts < Layout
      def logs
      	@logs || "Nothing yet..."
      end
      def count
      	@count
      end
    end
  end
end
