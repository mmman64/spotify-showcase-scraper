class ProjectAuthor < ActiveRecord::Base
  belongs_to :project
  belongs_to :author
end
