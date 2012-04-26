module Spree
  Spree::Order.class_eval do
    # Finalizes an in progress order after checkout is complete.
    # Called after transition to complete state when payments will have been processed
    def finalize!
      update_attribute(:completed_at, Time.now)
      update_attribute(:locale, I18n.locale)
      InventoryUnit.assign_opening_inventory(self)
      # lock any optional adjustments (coupon promotions, etc.)
      adjustments.optional.each { |adjustment| adjustment.update_attribute('locked', true) }
      OrderMailer.confirm_email(self).deliver

      self.state_events.create({
        :previous_state => 'cart',
        :next_state     => 'complete',
        :name           => 'order' ,
        :user_id        => (User.respond_to?(:current) && User.current.try(:id)) || self.user_id
      })
    end
  end
end