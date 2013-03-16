module Niouz
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

    attr_accessor :name, :description, :date_created

    def self.find_by_name(name)
      storage.by_name(name)
    end

    def self.exist?(name)
      !find_by_name(name).nil?
    end

    def self.each
      storage.all.each do |grp|
        yield grp
      end
    end

    # Returns the index of the first article (lowest numbered) in this
    # group. Note that articles are indexed starting from 1, and a
    # return value of 0 means the newsgroup is empty.
    def first
      return sync { i_first }
    end

    # Returns the index of the last article (highest numbered) in this
    # group. Note that articles are indexed starting from 1, and a
    # return value of 0 means the newsgroup is empty.
    def last
      return sync { i_last }
    end

    # Returns a string describing the state of this newsgroup,
    # as expected by the +LIST+ and +NEWSGROUPS+ commands.
    def metadata
      return sync { "#{name} #{i_last} #{i_first} y" }
    end

    # Tests whether this Newsgroup already existed at the given time.
    def existed_at?(aTime)
      return date_created >= aTime
    end

    # Returns an Article by number.
    def [](nb)
      return sync { articles[nb - 1] }
    end

    # Adds a new Article to this newsgroup.
    def add(article)
      sync {
        articles << article
        @i_first = 1
        @i_last = (@i_last || 0 ) + 1
      }
      #puts "adding to #{self.name}: #{i_first} #{i_last} #{article.id} <#{article.mid}>"
    end

    # Tests whether this newsgroup has an article numbered +nb+.
    def has_article?(nb)
      return sync { not articles[nb - 1].nil? }
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
