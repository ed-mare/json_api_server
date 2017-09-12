class CreateTopic < ActiveRecord::Migration[5.0]
  def change
    create_table :topics do |t|
      t.string :character
      t.string :book
      t.string :quote
      t.string :location
      t.date :published
      t.string :author
      t.timestamps
    end
  end
end
