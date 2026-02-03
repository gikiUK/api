# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create the first user
ihid_user = User.find_or_create_by!(email: "ihid@giki.io") do |u|
  u.password = "password"
  u.password_confirmation = "password"
end
ihid_user.confirm
puts "Created user: #{ihid_user.email}"

# Create the admin user
aron_user = User.find_or_create_by!(email: "aron@giki.io") do |u|
  u.admin = true
  u.password = "password"
  u.password_confirmation = "password"
end
aron_user.confirm
puts "Created admin user: #{aron_user.email}"
