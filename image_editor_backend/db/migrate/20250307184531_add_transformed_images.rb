class AddTransformedImages < ActiveRecord::Migration[8.0]
  def change
    create_table :transformed_images do |t|
      t.references :image, null: false, foreign_key: true  # Foreign key to images table
      t.timestamps
    end
  end
end
