module Niouz
  module Storage
    module ActiveRecord
      class ArticlesNewsgroup  < ::ActiveRecord::Base
        belongs_to :article
        belongs_to :newsgroup
      end
    end

  end
end
