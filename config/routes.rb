Rails.application.routes.draw do
  root to: 'companies#index'
  get "crawl", to: "companies#crawl_data"
  get "search", to: "companies#search"
  resources :companies do
    collection do
      get :redis
      get :export_csv
      post :import_csv
      post :import_job_csv
    end
  end
end
