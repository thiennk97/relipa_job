require 'nokogiri'
require 'open-uri'

class Company < ApplicationRecord
  HEADERS = %w[COMPANY_ID UUID CATEGORY_ID NAME TITLE CONTENT AVATAR TYPE ADDRESS].freeze

  has_one_attached :csv_file
  belongs_to :category
  validates :uid, uniqueness: true
  self.table_name = 'companies'
  searchkick language: "japanese", deep_paging: true

   def search_data
    {
      name: name,
      title: title,
      content: content,
    }
  end

  after_save :clear_cache
  after_destroy :clear_cache

  def self.face_data
    arr = []
    (1..100000).each do
      arr << Company.new(name: "name", type_company: "type_company", avatar: "avatar", title: "title", content: "content", address: "address", category_id: 1, uid: "uid_company")
    end
    Company.import arr
  end

  def self.crawl
    node_category = Nokogiri::HTML.parse(open("https://baseconnect.in/").read)
    node_category.css(".home__category li").each do |item|
      uid = item.css("a").first.values.first.split("/").last.strip.to_s
      name = item.css(".home__category__box__name").text.strip.to_s
      category = Category.find_or_create_by!(name: name, uid: uid)
      total_page = Nokogiri::HTML.parse(open("https://baseconnect.in/companies/category/#{uid}").read).css(".pagination a")[-2].text.to_i

      (1..total_page).to_a.each do |index|
        doc = Nokogiri::HTML.parse(open("https://baseconnect.in/companies/category/#{uid}?page=#{index}").read)

        doc.css(".searches__result__list").each do |parent|
          logger.info "======================================https://baseconnect.in/companies/category/#{uid}?page=#{index}"
          uid_company = parent.css(".searches__result__list__header__title a").first.values.first.split("/").last.strip
          next if Company.find_by(uid: uid_company).present?

          name = parent.css(".searches__result__list__header .searches__result__list__header__title").text.strip.to_s
          type_company = parent.css(".searches__result__list__header .searches__tag--listed").text.strip.to_s
          avatar = parent.css(".searches__result__list__conts .searches__result__list__conts__thumb img")[0].values[1].strip.to_s
          title = parent.css(".searches__result__list__conts .searches__result__list__conts__text__heading").text.strip.to_s
          content = parent.css(".searches__result__list__conts .searches__result__list__conts__text__excerpt").text.strip.to_s
          address = parent.css(".searches__result__list__conts .searches__result__list__conts__text__address").text.strip.to_s
          category_id = category.id
          begin
            Company.create(name: name, type_company: type_company, avatar: avatar, title: title, content: content, address: address, category_id: category_id, uid: uid_company)
          rescue
            next
          end
        end
      end
    end
  end

  def self.import_csv_c csv_file_path
    require 'csv'
    row_index = {
      COMPANY_ID: 0,
      UUID: 1,
      CATEGORY_ID: 2,
      NAME: 3,
      TITLE: 4,
      CONTENT: 5,
      AVATAR: 6,
      TYPE: 7,
      ADDRESS: 8
    }
    Company.transaction do
      csv = CSV.foreach(csv_file_path, headers: true, encoding: Encoding::SJIS).with_index do |row, index|
        $redis.set "row_line", index
        company = Company.find_by(uid: row[row_index[:UUID]])
        if company.present?
          company.update!(name: row[row_index[:NAME]], title:  row[row_index[:TITLE]], content: row[row_index[:CONTENT]], type_company: row[row_index[:TYPE]], address: row[row_index[:ADDRESS]], category_id: row[row_index[:CATEGORY_ID]], avatar: row[row_index[:AVATAR]])
        else
          Company.create!(uid: row[row_index[:UUID]], name: row[row_index[:NAME]], title:  row[row_index[:TITLE]], content: row[row_index[:CONTENT]], type_company: row[row_index[:TYPE]], address: row[row_index[:ADDRESS]], category_id: row[row_index[:CATEGORY_ID]], avatar: row[row_index[:AVATAR]])
        end
      end
    end
  end

  def self.test_es
    c = Company.search("小売業界の会社")
    print "\ntime: #{c.took}ms -- count: #{c.total_count}"
  end

  private
  def clear_cache
    $redis.del "posts"
  end
end
