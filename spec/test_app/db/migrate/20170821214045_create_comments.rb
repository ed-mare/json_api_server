class CreateComments < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.references :topic
      t.references :author
      t.string :title
      t.string :comment

      t.timestamps
    end
  end
end
