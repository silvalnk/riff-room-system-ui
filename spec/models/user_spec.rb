require "rails_helper"

RSpec.describe User, type: :model do
  it "requires a display name" do
    user = User.new(email_address: "a@example.com", password: "secret123", display_name: "")
    expect(user).not_to be_valid
  end
end
