require "rails_helper"

RSpec.describe "Rooms", type: :system do
  it "lists rooms and lets a guest listen without becoming DJ" do
    visit root_path
    expect(page).to have_content("Neon Floor")
    expect(page).to have_content("After Hours")

    click_link "Neon Floor"
    expect(page).to have_content("Cabine livre")
    expect(page).to have_content("Você está ouvindo. Crie uma conta para votar, entrar na fila e ser DJ.")
    expect(page).not_to have_button("Entrar na fila")
  end
end
