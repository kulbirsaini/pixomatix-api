json.cache! [@galleries], expires_in: 12.hours do
  json.array! @galleries, partial: 'images/image', as: :image
end
