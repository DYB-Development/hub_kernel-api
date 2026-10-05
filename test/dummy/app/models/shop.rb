module Shop
  extend HubKernel::Exposes

  exposes :price_of, takes: %i[item], writes: false

  def self.price_of(item:) = "#{item} costs 3"
end
