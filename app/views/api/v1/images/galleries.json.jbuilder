json.cache! [@galleries], expires_in: 12.hours do
  json.array! @galleries, partial: 'api/v1/images/image', as: :image
end
