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

class Rental
  attr_reader :id, :car_id, :car, :start_date, :end_date, :distance, :price

  def initialize(id, car_id, car, start_date, end_date, distance)
    @id = id
    @car_id = car_id
    @car = car
    @start_date = start_date
    @end_date = end_date
    @distance = distance
    @price = get_price
  end

  def get_price
    days_count = (Date.parse(end_date) - Date.parse(start_date)).to_i + 1
    day_price = 0
    (1..days_count).to_a.each do |day|
      day_price += get_price_per_day_with_discount(day)
    end
    return (day_price + distance * car.price_per_km).to_i
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

  def to_json
    return {id: id, price: price}
  end

end

class FileReader
  attr_accessor :input_file_path

  def initialize(input_file_path)
    @input_file_path = input_file_path
  end

  def read_json
    data = File.read(input_file_path)
    return JSON.parse(data)
  end

end

class CarsAndRentalsTransformer
  
  def transform(json)
    cars = json['cars'].map { |car| Car.new(car['id'], car['price_per_day'], car['price_per_km']) }
    rentals = json['rentals'].map { |rental| Rental.new(
      rental['id'], 
      rental['car_id'], 
      get_car(cars, rental['car_id']),
      rental['start_date'],
      rental['end_date'],
      rental['distance']
      ) }
  end

  def get_car(cars, car_id)
    cars.find { |car| car.id == car_id}
  end
end

class RentalsWriter
  attr_accessor :output_file_path

  def initialize(output_file_path)
    @output_file_path = output_file_path
  end

  def write(rentals)
    result = JSON.pretty_generate({ rentals: rentals.map(&:to_json) })
    output_file = File.new(output_file_path, "w")
    output_file.write(result)
    output_file.close 
  end
end

reader = FileReader.new('data.json')
transformer = CarsAndRentalsTransformer.new
writer = RentalsWriter.new('output.json')

json = reader.read_json
rentals = transformer.transform(json)
writer.write(rentals)