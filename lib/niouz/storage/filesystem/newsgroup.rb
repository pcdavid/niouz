module Niouz
  module Storage
    module Filesystem
      # Represents a newsgroup, i.e. a numbered sequence of Articles,
      # identified by a name. Note that article are numbered starting from
      # 1.
      #
      # This class does not read or write anything from the disk.
      # Thread-safe (I think).
      class Newsgroup
        # Creates a new, empty Newsgroup.
        # [+name+] the name of the Newsgroup (e.g. "comp.lang.ruby").
        # [+created+] the Time the newsgroup was created (posted).
        # [+description+] a short description of the newsgroup subject.
        include Model
        include Models::Newsgroup

        attr_accessor :name, :description, :date_created

        def self.find_by_name(name)
          storage.by_name(name)
        end

        def self.find_each
          all.each do |grp|
            yield grp
          end
        end

        def self.all
          storage.all
        end

        def self.newgroups(time, distribs)
          all.select do |group|
            group.existed_at?(time) && group.matches_distribs?(distribs)
          end
        end

        # Returns the index of the first article (lowest numbered) in this
        # group. Note that articles are indexed starting from 1, and a
        # return value of 0 means the newsgroup is empty.
        def min_pos
          return sync { i_first }
        end

        # Returns the index of the last article (highest numbered) in this
        # group. Note that articles are indexed starting from 1, and a
        # return value of 0 means the newsgroup is empty.
        def max_pos
          return sync { i_last }
        end

        # Returns a string describing the state of this newsgroup,
        # as expected by the +LIST+ and +NEWSGROUPS+ commands.
        def metadata
          return sync { "#{name} #{i_last} #{i_first} y" }
        end

        # Returns an Article by number.
        def article_by_pos(nb)
          return sync { articles[nb - 1] }
        end

        # @return [[Integer]] the positions of the articles in this group
        def article_pos
          body=[]
          articles.each_index do |idx|
            body << (idx+1).to_s
          end
          body
        end

        def articles_in_range(from, to)
          res={}
          (from .. to).each do |pos|
            if art=article_by_pos(pos)
              res[pos]=art
            end
          end
          res
        end

        # Adds a new Article to this newsgroup.
        def add(article)
          sync {
            articles << article
            @i_first = 1
            @i_last = (@i_last || 0) + 1
          }
          #puts "adding to #{self.name}: #{i_first} #{i_last} #{article.id} <#{article.mid}>"
        end

        # Returns an estimation of the number of articles in this newsgroup.
        def size_estimation
          return sync { i_last - i_first + 1 }
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

        def articles
          @articles ||= []
        end

        private
        def sync
          return lock.synchronize { yield }
        end

        attr_writer :i_first

        def i_first
          @i_first ||= 0
        end

        attr_writer :i_last

        def i_last
          @i_last ||= 0
        end

        def lock
          @lock ||= Mutex.new
        end


      end
    end

  end
end