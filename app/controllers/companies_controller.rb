require 'csv'
class CompaniesController < ApplicationController
  before_action :find_company, only: %i(update destroy)

  def index
    @companies = Company.all.page(params[:page]).per(50)
  end

  def redis
    @companies = Company.search params[:q]
    if @companies.size == 0
      @companies = fetch_companies
    end
  end

  def crawl_data
    Company.crawl
    redirect_to root_path
  end

  def edit; end

  def update; end

  def destroy
    @company.destroy
    redirect_to root_path
  end

  def search
    @results = Searchkick.search params[:q], models: [Company, Category]
  end

  def export_csv
    generated_csv =
      CSV.generate('', headers: Company::HEADERS, write_headers: true, force_quotes: true) do |csv|
        Company.first(10).each do |c|
          csv << [
            c.id,
            c.uid,
            c.category.id,
            c.name,
            c.title,
            c.content,
            c.avatar,
            c.type_company,
            c.address,
          ]
        end
      end
    respond_to do |format|
      format.csv do
        send_data generated_csv.encode(Encoding::SJIS, undef: :replace), type: 'text/csv; charset=shift_jis',
                  filename: "Company#{Time.current.strftime('%Y%m%d')}.csv"
      end
    end
  end

  def import_csv
    csv_file = params[:registration_sheet].tempfile
    Company.import_csv_c(csv_file.path)
    flash[:success] = 'Success!'
    redirect_to root_path, flash: {success: "Success!"}
  rescue => e
    redirect_to root_path, flash: {error: "Error in line #{$redis.get "row_line"} CSV ---------- #{e}!"}
  end

  def import_job_csv
    File.open("#{Rails.root}/public/file.csv", "wb") { |f| f.write(params[:registration_sheet].read) }

    ImportCsvWorker.perform_async("#{Rails.root}/public/file.csv")
    flash[:success] = 'Success!'
    redirect_to root_path, flash: {success: "Success!"}
  rescue => e
    redirect_to root_path, flash: {error: "Error in line #{$redis.get "row_line"} CSV ---------- #{e}!"}
  end

  def find_company
    @company = Company.find_by(id:params[:id])
  end

  def fetch_companies
    companies = $redis.get "companies"

    if companies.nil?
      companies = Company.all.order(id: :desc).to_json
      $redis.set "companies", companies
    end

    JSON.load companies
  end
end
