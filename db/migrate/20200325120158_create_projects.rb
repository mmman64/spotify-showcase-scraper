class CreateProjects < ActiveRecord::Migration[5.2]
  def change
    create_table :projects do |t|
      t.string :url
      t.string :title
      t.string :description
      t.string :project_link
      t.string :site_response
      t.integer :developer_showcase_id

      t.timestamps
    end
  end
end
