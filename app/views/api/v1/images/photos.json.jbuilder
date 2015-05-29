json.cache! [@photos], expires_in: 12.hours do
  json.array! @photos, partial: 'api/v1/images/image', as: :image
end
