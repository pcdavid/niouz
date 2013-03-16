module Niouz
  module Storage
    module Filesystem
      #reads and caches filesystem db
      class ArticleFile
        def self.load(dirname)
          @article_dir = File.join(dirname, 'articles')
          @last_file_id = 0
          @models = Hash.new
          @lock = Mutex.new

          Dir.foreach(@article_dir) do |fname|
            next if fname[0] == ?.
            @last_file_id = [@last_file_id, fname.to_i].max
            load_article(fname.to_i, File.join(@article_dir, fname))
          end

        end

        #returns hash of users by username
        def self.by_message_id(name)
          @models[name]
        end

        def self.save(article, content)
          begin
            @lock.synchronize {
              @last_file_id += 1;
              fname_id = "%06d" % [@last_file_id]
              fname=File.join(@article_dir, fname_id)
              File.open(fname, "w") { |f| f.write(content) }
              article.filename=fname
              article.id=@last_file_id
              register_article(article)
            }
            return true
          rescue
            return false
          end
        end

        private
        def self.load_article(id, fname)
          content=File.read(fname)
          article = Article.new(:filename => fname, :id => id, :content => content)
          register_article(article)
        end

        def self.register_article(article)
          @models[article.mid] = article
          article.newsgroup_names.each do |gname|
            group=Newsgroup.find_by_name(gname)
            group.add(article) if group
          end
        end


      end
    end
  end
end