json.cache! [@images], expires_in: 12.hours do
  json.array! @images, partial: 'api/v1/images/image', as: :image
end
