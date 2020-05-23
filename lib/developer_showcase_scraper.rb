class DeveloperShowcaseScraper
  attr_accessor :developer_showcase, :doc

  def initialize(base_url)
    @base_url = base_url
    @doc = Nokogiri::HTML(open("#{base_url}/community/showcase/"))
    @developer_showcase = DeveloperShowcase.new(url: "#{base_url}/community/showcase/")
    @developer_showcase.save!
  end

  def scrape
    get_project_links
    scrape_projects

    @developer_showcase
  end

  def get_project_links
    @project_links = @doc.css("div.tile-container-3-col a[href]").map { |element| element["href"] }
  end

  def scrape_projects
    @project_links.each do |link|
      # make link available to scrape_project_page
      @link = link
      @project_url = "#{@base_url}#{link}"
      @project_page = Nokogiri::HTML(open(@project_url))

      scrape_project_page
      add_project_to_showcase unless @project_properties.empty?
    end
  end

  def scrape_project_page
    @project_properties = {}

    if is_page_valid?
      @project_properties[:url] = @link
      @project_properties[:title] = @project_page.css(".display-1").text.strip
      @project_properties[:description] = @project_page.css(".showcase-description").text.strip

      website_link = @project_page.at_css('a:contains("Website")')
      @project_properties[:project_link] = website_link["href"]
      @project_properties[:developer_showcase_id] = @developer_showcase.id
      @project_properties[:authors] = get_project_authors
    end

    @project_properties
  end

  def is_page_valid?
    # page link always present so not checked
    if @project_page.css(".display-1") &&
       @project_page.css(".showcase-description") &&
       @project_page.at_css('a:contains("Website")') &&
       @project_page.at_css('li:contains("Submitted by")')
      return true
    end

    false
  end

  def get_project_authors
    # two authors usually represented as: "Submitted by: Aliza Aufrichtig & Edward Lee"
    authors_list_item_text = @project_page.at_css('li:contains("Submitted by")').text.strip
    # remove "Submitted by: "
    authors_names = authors_list_item_text.gsub("Submitted by: ", "")
    # get authors into array without whitespace
    if authors_names.include?("&")
      @authors = authors_names.split("&").map { |author| author.strip }
    else
      @authors = [authors_names.strip]
    end

    @author_obj_arr = []

    @authors.map do |author_name|
      author = Author.new(name: author_name)
      author.save
      @author_obj_arr << author
    end

    @author_obj_arr
  end

  def add_project_to_showcase
    @developer_showcase.add_project(@project_properties)
  end

  # If number of links doesn't match number of projects then the scraper wasn't
  # able to create all projects most likely due to inconsistent formatting on
  # project page
  def get_scrape_success_report
    # colour code messages
    pastel = Pastel.new

    # get counts of links and projects
    project_count = @developer_showcase.projects.count
    link_count = get_project_links.count

    # prepare error messages
    link_scraper_error = pastel.red("Links scraper error!\nCheck if HTML formatting has changed!")
    project_scraper_error = pastel.red("Project scraper error!\nCheck if HTML formatting has changed!")
    partial_scraper_error = pastel.cyan("Not all projects were scraped!\nEnsure HTML consistency in project pages!")
    success_message = pastel.green("Success!")

    @report = {}

    if link_count === 0
      @report[:message] = link_scraper_error
      @report[:link_count] = 0
      @report[:project_count] = 0
    else
      if project_count === 0
        @report[:message] = project_scraper_error
        @report[:link_count] = link_count
        @report[:project_count] = 0
      elsif project_count === link_count
        @report[:message] = success_message
        @report[:link_count] = link_count
        @report[:project_count] = project_count
      else
        @report[:message] = partial_scraper_error
        @report[:link_count] = link_count
        @report[:project_count] = project_count
      end
    end

    render_scrape_report
  end

  def render_scrape_report
    header = ["Message", "No.links", "No.projects"]
    rows = [[@report[:message], @report[:link_count], @report[:project_count]]]
    table = TTY::Table.new header, rows

    puts table.render(:unicode, multiline: true)
  end
end
