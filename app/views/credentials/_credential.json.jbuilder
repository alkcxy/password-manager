json.extract! credential, :id, :name, :user, :password, :url, :note, :created_at, :updated_at
json.url credential_url(credential, format: :json)
