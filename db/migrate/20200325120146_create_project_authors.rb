class CreateProjectAuthors < ActiveRecord::Migration[5.2]
  def change
    create_table :project_authors do |t|
      t.integer :project_id
      t.integer :author_id

      t.timestamps
    end
  end
end
