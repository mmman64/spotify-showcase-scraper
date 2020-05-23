class InvalidType < StandardError; end

class DeveloperShowcase < ActiveRecord::Base
  attribute :tested, :integer, default: 0
  has_many :projects

  def save
    self.save!
  end

  def add_project(project_properties)
    url = project_properties[:url]
    title = project_properties[:title]
    description = project_properties[:description]
    project_link = project_properties[:project_link]
    showcase_id = project_properties[:developer_showcase_id]
    authors = project_properties[:authors]

    project = Project.new(
      url: url,
      title: title,
      description: description,
      project_link: project_link,
      developer_showcase_id: showcase_id,
    )

    project.save

    create_project_author(project.id, authors)
  end

  def check_project_sites_status
    @report = {}

    self.projects.map do |project|
      @proj_id = project.id
      @link = project[:project_link]
      title = project[:title]
      @report[title] = {}
      @report[title][:authors] = get_authors_as_strings(project)
      @report[title][:site_response] = query_site

      project.update(site_response: @report[title][:site_response])
    end
  end

  def get_authors_as_strings(project)
    author_names = project.authors.map { |author| author.name }

    if author_names.length > 1
      authors_string = author_names.join(" & ")
    else
      authors_string = author_names.first
    end

    authors_string
  end

  def query_site
    max_retries = 3
    retry_number = 0

    begin
      response = HTTParty.get(@link, { read_timeout: 1, open_timeout: 1 })
      message = response.message
    rescue HTTParty::Error, SocketError, Net::ReadTimeout, Net::OpenTimeout => error
      if retry_number < max_retries
        retry_number += 1
        retry
      else
        message = "This website is unavailable"
      end
    end
    message
  end

  def create_project_author(project_id, authors)
    authors.map do |author|
      project_author = ProjectAuthor.new(project_id: project_id, author_id: author.id)
      project_author.save!
    end
  end

  def retrieve_and_render_showcase_report
    showcase_projects = self.projects
    @report = {}

    showcase_projects.map do |project|
      title = project[:title]
      @report[title] = {}
      @report[title][:authors] = get_authors_as_strings(project)
      @report[title][:site_response] = project[:site_response]
    end
    render_site_health_check_report
  end

  def render_site_health_check_report
    rows = []
    # k -> project names, v -> authors, site_response
    @report.map do |k, v|
      row = []
      row << k
      row << v[:authors]
      row << v[:site_response]

      rows << row
    end

    header = ["Project", "Authors", "Response"]
    table = TTY::Table.new header, rows

    puts table.render(:unicode, multiline: true)
  end
end
