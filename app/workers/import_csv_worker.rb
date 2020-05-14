require 'csv'
class ImportCsvWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, backtrace: true

  def perform csv_file
    Company.import_csv_c(csv_file)
    File.delete(csv_file) if File.exist?(csv_file)
  end
end
