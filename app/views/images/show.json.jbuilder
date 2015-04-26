if @image.images.count > 0
  json.array! @image.images.ordered.collect(&:id)
elsif @image.parent.present?
  json.array! @image.parent.images.ordered.collect(&:id)
end
