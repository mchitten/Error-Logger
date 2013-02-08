class App
  module Views
    class MorePosts < Layout
      def logs
      	@logs || "Nothing yet..."
      end
    end
  end
end
