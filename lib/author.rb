class Author < ActiveRecord::Base
  has_many :project_authors
  has_many :projects, :through => :project_authors
end
