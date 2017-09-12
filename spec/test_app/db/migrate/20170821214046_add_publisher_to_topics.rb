
class AddPublisherToTopics < ActiveRecord::Migration[5.0]
  def change
    add_column :topics, :publisher_id, :integer
  end
end
