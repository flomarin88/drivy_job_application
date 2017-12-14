require 'json'
require 'Date'

# your code
class Car
  attr_reader :id, :price_per_day, :price_per_km

  def initialize(id, price_per_day, price_per_km)
    @id = id
    @price_per_day = price_per_day
    @price_per_km = price_per_km
  end
end

class Options
  attr_reader :deductible_reduction

  def initialize(rental)
    @deductible_reduction = get_deductible_reduction_price(rental)
  end

  def get_deductible_reduction_price(rental)
    price = 0
    if rental.deductible_reduction
      price = (rental.days_count * 400).to_i
    end
    price
  end

end

class Commission
  attr_reader :insurance_fee, :assistance_fee, :drivy_fee, :total

  def initialize(rental)
    @total = (rental.price * 0.3).to_i
    @insurance_fee = (total * 0.5).to_i
    @assistance_fee = (rental.days_count * 100).to_i
    @drivy_fee = (total - insurance_fee - assistance_fee).to_i
  end

end

class Action
  attr_reader :who, :type, :amount
  
  def initialize(who, type, amount)
    @who = who
    @type = type
    @amount = amount
  end

  def to_json
    {who: who, type: type, amount: amount}
  end
end

class Rental
  attr_reader :id, :car_id, :car, :start_date, :end_date, :distance, :deductible_reduction, :price, :options, :commission, :actions

  def initialize(id, car_id, car, start_date, end_date, distance, deductible_reduction)
    @id = id
    @car_id = car_id
    @car = car
    @start_date = start_date
    @end_date = end_date
    @distance = distance
    @price = get_price
    @deductible_reduction = deductible_reduction
    @options = Options.new(self)
    @commission = Commission.new(self)
    @actions = get_actions
  end

  def days_count
    (Date.parse(end_date) - Date.parse(start_date)).to_i + 1
  end

  def get_price
    day_price = 0
    (1..days_count).to_a.each do |day|
      day_price += get_price_per_day_with_discount(day)
    end
    (day_price + distance * car.price_per_km).to_i
  end

  def get_price_per_day_with_discount(day)
    case 
    when day > 10
      car.price_per_day * 0.5
    when day > 4
      car.price_per_day * 0.7
    when day > 1
      car.price_per_day * 0.9
    else 
      car.price_per_day
    end
  end

  def get_actions
    [
      Action.new('driver', 'debit', price + options.deductible_reduction),
      Action.new('owner', 'credit', price - commission.total),
      Action.new('insurance', 'credit', commission.insurance_fee),
      Action.new('assistance', 'credit', commission.assistance_fee),
      Action.new('drivy', 'credit', commission.drivy_fee + options.deductible_reduction)
    ]
  end

end

class RentalModification
  attr_reader :id, :rental_id, :previous_rental, :current_rental, :actions

  def initialize(id, rental_id, previous_rental, current_rental)
    @id = id
    @rental_id = rental_id
    @previous_rental = previous_rental
    @current_rental = current_rental
    @actions = get_actions(previous_rental.actions, current_rental.actions)
  end

  def get_delta(previous_action, current_action)
    amount = current_action.amount - previous_action.amount
    type = current_action.type
    if amount < 0
      type = current_action.type == 'credit' ? 'debit' : 'credit'
    end
    return Action.new(previous_action.who, type, amount.abs)
  end

  def get_actions(previous_actions, current_actions)
    previous_actions.each_with_index.map { |val,index| get_delta(val, current_actions[index]) }
  end

  def to_json
    {
      id: id, 
      rental_id: rental_id,
      actions: actions.map(&:to_json)
    }
  end
end

class FileReader
  attr_accessor :input_file_path

  def initialize(input_file_path)
    @input_file_path = input_file_path
  end

  def read_json
    data = File.read(input_file_path)
    JSON.parse(data)
  end

end

class CarsAndRentalsTransformer
  
  def transform(json)
    cars = transform_cars(json)
    rentals = transform_rentals(json, cars)
    return transform_rental_modifications(json, rentals)
  end

  def transform_cars(json)
    cars = json['cars'].map { |car| Car.new(car['id'], car['price_per_day'], car['price_per_km']) }
  end

  def transform_rentals(json, cars)
    rentals = json['rentals'].map { |rental| Rental.new(
      rental['id'], 
      rental['car_id'], 
      get_item(cars, rental['car_id']),
      rental['start_date'],
      rental['end_date'],
      rental['distance'],
      rental['deductible_reduction']
      ) }
  end

  def transform_rental_modifications(json, rentals)
    rental_modifications = []
    json['rental_modifications'].each do |rental_modification|
      rental = get_item(rentals, rental_modification['rental_id'])
      rental_modification = RentalModification.new(
        rental_modification['id'],
        rental_modification['rental_id'],
        rental,
        Rental.new(
          nil, 
          rental.car_id,
          rental.car,
          rental_modification['start_date'] || rental.start_date,
          rental_modification['end_date'] || rental.end_date,
          rental_modification['distance'] || rental.distance,
          rental.deductible_reduction
        )
      )
      rental_modifications.push(rental_modification)
    end
    return rental_modifications
  end

  def get_item(list, item_id)
    list.find { |item| item.id == item_id}
  end
end

class RentalsWriter
  attr_accessor :output_file_path

  def initialize(output_file_path)
    @output_file_path = output_file_path
  end

  def write(rental_modifications)
    result = JSON.pretty_generate({ rental_modifications: rental_modifications.map(&:to_json) })
    output_file = File.new(output_file_path, "w")
    output_file.write(result)
    output_file.close 
  end
end

reader = FileReader.new('data.json')
transformer = CarsAndRentalsTransformer.new
writer = RentalsWriter.new('output_new.json')

json = reader.read_json
rental_modifications = transformer.transform(json)
writer.write(rental_modifications)