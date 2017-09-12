class Comment < ApplicationRecord
  belongs_to :topic
  belongs_to :author, class_name: 'User'
end
