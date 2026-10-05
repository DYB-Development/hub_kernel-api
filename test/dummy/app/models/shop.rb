module Shop
  extend HubKernel::Exposes

  exposes :price_of, takes: %i[item], writes: false

  def self.price_of(item:) = "#{item} costs 3"

  exposes :restock, takes: %i[item], writes: true

  def self.restock(item:)
    raise HubKernel::Refused, "The #{item} shelf is full" if item == "ice"

    "#{item} restocked"
  end

  exposes :stock_of, takes: %i[item_id], writes: false

  def self.stock_of(item_id:) = raise(ActiveRecord::RecordNotFound.new("Couldn't find Shelf item", "Shelf::Item", "id", item_id))
end
