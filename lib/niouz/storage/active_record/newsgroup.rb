module Niouz
  module Storage
    module ActiveRecord
      # Represents a newsgroup, i.e. a numbered sequence of Articles,
      # identified by a name. Note that article are numbered starting from
      # 1.
      #
      # This class does not read or write anything from the disk.
      # Thread-safe (I think).
      class Newsgroup < ::ActiveRecord::Base
        include Models::Newsgroup
        has_many :articles_newsgroups
        has_many :articles, :through => :articles_newsgroups

        def self.newgroups(time, distribs)
          where(["created_at >= ?", time]).all
          #&& group.matches_distribs?(distribs)
        end


        def date_created
          created_at
        end

        # Returns a string describing the state of this newsgroup,
        # as expected by the +LIST+ and +NEWSGROUPS+ commands.
        def metadata
          return "#{name} #{max_pos} #{min_pos} y"
        end

        # Returns an Article by number.
        def article_by_pos(pos)
          if empty?
            nil
          else
            Article.joins(:articles_newsgroups).where(["newsgroup_id = ? and pos = ?", self.id, pos]).first
          end
        end

        # @return [[Integer]] the positions of the articles in this group
        def article_pos
          articles_newsgroups.order('pos').map(&:pos)
        end

        def articles_in_range(from, to)
          res={}
          ArticlesNewsgroup.includes(:article).
              where(["pos >= ? and pos <= ?", from, to]).each do |an|
            res[an.pos]=an.article
          end
          res
        end

        # Returns an estimation of the number of articles in this newsgroup.
        def size_estimation
          return articles_count
        end

        # Returns the smallest valid article number strictly superior to
        # +from+, or nil if there is none.
        def next_article(from)
          sync {
            current = from + 1
            while current <= i_last
              break if articles[current - 1]
              current += 1
            end
            (current > i_last) ? nil : current
          }
        end

        # Returns the greatest valid article number strictly inferior to
        # +from+, or nil if there is none.
        def previous_article(from)
          sync {
            current = from - 1
            while current >= i_first
              break if articles[current - 1]
              current -= 1
            end
            (current < i_first) ? nil : current
          }
        end

        #this should be locked and run in a transaction
        def add_article(article)
          self.min_pos = 1 if self.min_pos == 0
          self.max_pos +=1
          self.articles_count += 1
          self.save!
          ArticlesNewsgroup.create!(:pos => max_pos, :article_id => article.id, :newsgroup_id => self.id)
        end

      end
    end

  end
end