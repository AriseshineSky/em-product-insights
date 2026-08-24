class CreateMerchantProductChecks < ActiveRecord::Migration[8.1]
  def change
    create_table :merchant_product_checks do |t|
      t.bigint :product_id, null: false
      t.string :source, null: false
      t.string :handle
      t.string :offer_id
      t.string :state, null: false, default: "not_found"
      t.string :title
      t.string :availability
      t.bigint :price_micros
      t.string :currency
      t.string :merchant_product_name
      t.string :error_message
      t.datetime :checked_at, null: false

      t.timestamps
      t.index %i[product_id source], unique: true
      t.index :source
      t.index :checked_at
    end
  end
end
