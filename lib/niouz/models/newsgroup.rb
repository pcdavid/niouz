module Niouz
  module Models
    module Newsgroup
      #class has to implement
      #find_by_name
      #find_each
      #all
      #newgroups(time,distribs)

      #instance has to implement
      #attributes: name,description,date_created
      #assocs: articles
      #first
      #last
      #metadata
      #article_by_pos(Integer)
      #add(article)
      #size_estimation
      #next_article
      #previous article

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
      end

      def empty?
        min_pos == 0
      end

      def default_pos
        empty? ? nil : min_pos
      end

      # Tests whether this Newsgroup already existed at the given time.
      def existed_at?(aTime)
        return date_created >= aTime
      end

      def matches_distribs?(distribs) # TODO
        if distribs.nil? or distribs.empty?
          return true
        else
          distribs.each do |dist|
            return true if name[0..dist.length] == dist
          end
          return false
        end
      end
    end
  end
end
