class AddTitleToArticles < ActiveRecord::Migration[4.2]
  def change
    add_column :articles, :title, :string
  end
end
