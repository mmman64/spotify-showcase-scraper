class DeveloperShowcaseController
  BASE_URL = "https://developer.spotify.com"

  def initialize
    @pastel = Pastel.new
    puts @pastel.green.underline("*** Spotify Developer Showcase Tester ***")

    spinner = TTY::Spinner.new("[:spinner] Scraping showcase page...", format: :bouncing_ball)
    spinner.auto_spin

    @scraper = DeveloperShowcaseScraper.new(BASE_URL)
    @developer_showcase = @scraper.scrape

    spinner.stop("Done!")
    sleep(1)
  end

  def call
    @prompt = TTY::Prompt.new
    main_menu
  end

  def main_menu
    system("clear")
    puts @pastel.green.underline("*** Spotify Developer Showcase Tester ***")

    menu_choice = @prompt.select("\n",
                                 "1. Test projects",
                                 "2. Test listings",
                                 "3. View previous reports",
                                 "4. Exit")

    case menu_choice
    when "1. Test projects"
      test_projects
    when "2. Test listings"
      scraper_test
    when "3. View previous reports"
      display_previous_reports
    when "4. Exit"
      quit
    else
      puts "\nInvalid option, try again!\n"
    end
  end

  def scraper_test
    @scraper.get_scrape_success_report
    next_action
  end

  def test_projects
    spinner = TTY::Spinner.new("[:spinner] Testing status of project sites...", format: :bouncing_ball)
    spinner.auto_spin

    @developer_showcase.check_project_sites_status
    @developer_showcase.tested = 1
    @developer_showcase.save!

    spinner.stop("Done!")
    sleep(1)
    @developer_showcase.render_site_health_check_report

    next_action
  end

  def display_previous_reports
    system("clear")
    puts @pastel.green.underline("*** Spotify Developer Showcase Tester ***")

    reports = DeveloperShowcase.where(tested: 1)

    unless reports.empty?
      report_options = reports.map.with_index(1) do |report, index|
        "#{index}. Created at: #{report.created_at}"
      end

      report_options << "#{report_options.length + 1}. Return to menu"
      report_options << "#{report_options.length + 1}. Exit"

      report_selection = @prompt.select("\n", report_options)

      if report_selection.include?("Return to menu")
        main_menu
      elsif report_selection.include?("Exit")
        quit
      else
        selection_datetime = report_selection[-23, 23]

        showcase = DeveloperShowcase.select { |showcase| showcase.created_at.to_s == selection_datetime }.first
        showcase.retrieve_and_render_showcase_report
      end
    end

    next_action
  end

  def next_action
    response = @prompt.select("\nReturn to menu or exit?", "Return to menu", "Exit")
    response === "Return to menu" ? main_menu : quit
  end

  def quit
    system("clear")
    exit(0)
  end
end
