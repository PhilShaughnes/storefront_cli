require 'rubygems'
require 'bundler/setup'
require 'tty'
require 'active_record'
require 'sqlite3'
require 'pry'
require_relative 'models/user'
require_relative 'models/address'
require_relative 'models/item'
require_relative 'models/order'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3',
  :database => 'db/store.sqlite3'
)
# Your code here
prompt = TTY::Prompt.new
answers =[]

# How many users are there?
answers << User.count

# What are the 5 most expensive items?
Item.order(price: :desc).limit(5).each_with_index do |item, i|
  answers << "#{i+1}) #{item.title}:$#{item.price}"
end
print "\n"
# What's the cheapest book?
cheapest_book = Item.where("category LIKE '%Books%'").order(:price).first.title
answers << "#{cheapest_book} is the cheapest book"

# Who lives at "6439 Zetta Hills, Willmouth, WY"?
lives_here = Address.find_by(street: "6439 Zetta Hills").user
answers << "#{lives_here.first_name} #{lives_here.last_name}"

#Do they have another address?
add = lives_here.addresses.where.not(street: "6439 Zetta Hills").first
answers << "#{add.street}\n#{add.city} #{add.state}, #{add.zip}"

# Correct Virginie Mitchell's address to "New York, NY, 10108".
virginie = User.find_by(first_name: "Virginie", last_name: "Mitchell")
virginie.addresses.find_by(state: "NY").update(city: "New York", state: "NY", zip: "10108")
v_address = virginie.addresses.find_by(state: "NY")
answers << "Updated address:\n#{v_address.street}\n#{v_address.city} #{v_address.state}, #{v_address.zip}"

# How much would it cost to buy one of each tool?
tool_cost = "$#{Item.where("category LIKE '%tools%'").sum(:price)}"
answers << "one of each tool would cost #{tool_cost}"

# How many total items did we sell?
answers << "#{Order.sum(:quantity)} items were sold"

# How much was spent on books?
list = Item.joins(:orders).where("category LIKE '%Books%'").sum("price * quantity")
answers << "$#{list} spent on books"

##################
# Adventure MODE #
##################

# What item was ordered most often?
ordered_by_item = Order.joins(:item).group(:title).sum(:quantity).sort_by{|k,v| -v}
answers << "#{ordered_by_item.first[0]} was ordered #{ordered_by_item.first[1]} times."

#Grossed the most money?
gross_by_item = Order.joins(:item).group(:title).sum("quantity*price").sort_by{|k,v| -v}
answers << "#{gross_by_item.first[0]} brought in $#{gross_by_item.first[1]}"

# What user spent the most?
spent_by_user = Order.joins(:item).group(:user_id).sum("quantity*price").sort_by{|k,v| -v}
spendiest_user = User.find_by(id: spent_by_user.first[0])

answers << "#{spendiest_user.first_name} #{spendiest_user.last_name} spent $#{spent_by_user.first[1]}"

# What were the top 3 highest grossing categories?
gross_by_category = Order.joins(:item).group(:category).sum("quantity*price").sort_by{|k,v| -v}.first(3)

gross_by_category.each_with_index do |cat, i|
  answers << "#{i+1}) #{cat[0]} : $#{cat[1]}"
end

puts answers
# Simulate buying an item by inserting a User from command line input (ask the user for their information) and an Order for that User (have them pick what they'd like to order and other needed order information).
if prompt.yes?("would you like buy something?")
  user_firstname = prompt.ask("Enter your first name: ")
  user_lastname = prompt.ask("Enter your first name: ")
  user_email = prompt.ask("Enter your email: ")

  item_ordered = prompt.select("choose an item to buy", Item.order(:price).group_by{|i| i[:title]})[0]

  quantity_ordered = prompt.ask("Enter how many of that item you want: ").to_i

  newuser = User.create(first_name: user_firstname, last_name: user_lastname, email: user_email)

  Order.create(user_id: newuser.id, item_id: item_ordered.id, quantity: quantity_ordered)
  puts "Thank you, order complete!"
end
