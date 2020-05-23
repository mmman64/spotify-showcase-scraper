class Project < ActiveRecord::Base
  belongs_to :developer_showcase
  has_many :project_authors
  has_many :authors, :through => :project_authors

  def self.get_authors(id)
    project_authors = ProjectAuthor.where(project_id: id)
    authors = project_authors.map do |project_author|
      Author.where(id: project_author[:author_id])
    end
  end
end
