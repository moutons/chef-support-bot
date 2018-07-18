require 'action_view'
require 'action_view/helpers'

class Person < ApplicationRecord
  include ActionView::Helpers::DateHelper
  belongs_to :product, optional: true
  has_many :tickets

  validates :slack_id, uniqueness: { message: "id already registered" }

  def status(all = false)
    if available?
      "#{slack_handle} is *available* and working on *#{working_on}* tickets"
    elsif all
      "#{slack_handle} was marked *away* #{time_ago_in_words(self.updated_at)} ago"
    end
  end

  def user_mention
    "<@#{slack_id}>"
  end

  def working_on
    reload
    self.product.nil? ? "any" : self.product.name
  end

  def set_away
    self.update_attribute(:available, false)
  end

  def update_email(email = nil)
    self.update_attribute(:slack_email, email)
  end

  def set_here(product = nil)
    Rails.logger.info product.inspect
    self.product = product
    self.available = true

    self.save
  end
end
