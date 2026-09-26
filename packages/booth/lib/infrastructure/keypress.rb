class Keypress < ApplicationRecord
  belongs_to :room
  belongs_to :queue_entry
end
