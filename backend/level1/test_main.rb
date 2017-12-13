require_relative 'main'
require 'minitest/autorun'

class TestCar < Minitest::Test
  
  def test_car_initilisation
    # Given
    # When
    car = Car.new(1, 2000, 10)

    # Then
    assert_equal 1, car.id
    assert_equal 2000, car.price_per_day
    assert_equal 10, car.price_per_km
  end

end

class TestRental < Minitest::Test
  
  def test_rental_static_initilisation
    # Given
    car = Car.new(23, 2000, 10)

    # When
    rental = Rental.new(1, 23, car, '2017-12-8', '2017-12-10', 100)

    # Then
    assert_equal 1, rental.id
    assert_equal 23, rental.car_id
    assert_equal car, rental.car
    assert_equal '2017-12-8', rental.start_date
    assert_equal '2017-12-10', rental.end_date
    assert_equal 100, rental.distance
  end

  def test_rental_price_initilisation
    # Given
    car1 = Car.new(1, 2000, 10)
    car2 = Car.new(2, 3000, 15)

    # When
    rental1 = Rental.new(1, 1, car1, '2017-12-8', '2017-12-10', 100)
    rental2 = Rental.new(2, 1, car1, '2017-12-14', '2017-12-18', 550)
    rental3 = Rental.new(3, 2, car2, '2017-12-8', '2017-12-10', 150)

    # Then
    assert_equal 7000, rental1.price
    assert_equal 15500, rental2.price
    assert_equal 11250, rental3.price
  end

  def test_to_json
    # Given
    car = Car.new(23, 2000, 10)
    rental = Rental.new(1, 23, car, '2017-12-8', '2017-12-10', 100)
    
    # When
    result = rental.to_json

    # Then
    expected_result = {id: 1, price: 7000}
    assert_equal expected_result, result
  end

  class TestCarsAndRentalsTransformer < Minitest::Test

    def test_get_car
      # Given
      car1 = Car.new(1, 2000, 10)
      car2 = Car.new(2, 3000, 15)

      transformer = CarsAndRentalsTransformer.new

      # When
      result = transformer.get_car([car1, car2], 2)

      # Then
      assert_equal car2, result
    end
  end

end