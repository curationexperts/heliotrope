#Add footer_block_a and footer_block_c to presses db
class AddFooterBlocksToPresses < ActiveRecord::Migration[4.2]
  def change
    add_column(:presses, :footer_block_a, :text)
    add_column(:presses, :footer_block_c, :text)
  end
end
