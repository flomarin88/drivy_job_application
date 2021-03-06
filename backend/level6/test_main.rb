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
    rental = Rental.new(1, 23, car, '2017-12-8', '2017-12-10', 100, true)

    # Then
    assert_equal 1, rental.id
    assert_equal 23, rental.car_id
    assert_equal car, rental.car
    assert_equal '2017-12-8', rental.start_date
    assert_equal '2017-12-10', rental.end_date
    assert_equal 100, rental.distance
    assert_equal true, rental.deductible_reduction
  end

  def test_rental_price
    # Given
    car1 = Car.new(1, 2000, 10)
    
    # When
    rental1 = Rental.new(1, 1, car1, '2015-12-8', '2015-12-8', 100, true)
    rental2 = Rental.new(2, 1, car1, '2015-03-31', '2015-04-01', 300, false)
    rental3 = Rental.new(3, 2, car1, '2015-07-3', '2015-07-14', 1000, true)

    # Then
    assert_equal 3000, rental1.price
    assert_equal 6800, rental2.price
    assert_equal 27800, rental3.price
  end

  def test_commission
    # Given
    car1 = Car.new(1, 2000, 10)
    
    # When
    rental1 = Rental.new(1, 1, car1, '2015-12-8', '2015-12-8', 100, true)

    # Then
    assert_equal 450, rental1.commission.insurance_fee
    assert_equal 100, rental1.commission.assistance_fee
    assert_equal 350, rental1.commission.drivy_fee
  end

  def test_deductible_reduction
    # Given
    car1 = Car.new(1, 2000, 10)
    
    # When
    rental1 = Rental.new(1, 1, car1, '2015-12-8', '2015-12-8', 100, true)
    rental2 = Rental.new(2, 1, car1, '2015-03-31', '2015-04-01', 300, false)

    # Then
    assert_equal 400, rental1.options.deductible_reduction
    assert_equal 0, rental2.options.deductible_reduction
    
  end

  def test_to_json_with_longer_rental
    # Given
    car = Car.new(23, 2000, 10)
    previous_rental = Rental.new(1, 1, car, '2015-12-8', '2015-12-8', 100, true)
    current_rental = Rental.new(1, 1, car, '2015-12-8', '2015-12-10', 150, true)
    rental_modification = RentalModification.new(1, 1, previous_rental, current_rental)

    # When
    result = rental_modification.to_json

    # Then
    expected_result = {
      id: 1,
      rental_id: 1,
      actions: [
        {
          who: 'driver',
          type: 'debit',
          amount: 4900
        },
        {
          who: 'owner',
          type: 'credit',
          amount: 2870
        },
        {
          who: 'insurance',
          type: 'credit',
          amount: 615
        },
        {
          who: 'assistance',
          type: 'credit',
          amount: 200
        },
        {
          who: 'drivy',
          type: 'credit',
          amount: 1215
        }
      ]
    }
    assert_equal expected_result, result
  end

  def test_to_json_with_shorter_rental
    # Given
    car = Car.new(23, 2000, 10)
    previous_rental = Rental.new(3, 1, car, '2015-07-3', '2015-07-14', 1000, true)
    current_rental = Rental.new(3, 1, car, '2015-07-4', '2015-07-14', 1000, true)
    rental_modification = RentalModification.new(2, 3, previous_rental, current_rental)

    # When
    result = rental_modification.to_json

    # Then
    expected_result = {
      id: 2,
      rental_id: 3,
      actions: [
        {
          who: 'driver',
          type: 'credit',
          amount: 1400
        },
        {
          who: 'owner',
          type: 'debit',
          amount: 700
        },
        {
          who: 'insurance',
          type: 'debit',
          amount: 150
        },
        {
          who: 'assistance',
          type: 'debit',
          amount: 100
        },
        {
          who: 'drivy',
          type: 'debit',
          amount: 450
        }
      ]
    }
    assert_equal expected_result, result
  end

  class TestCarsAndRentalsTransformer < Minitest::Test

    def test_get_item
      # Given
      car1 = Car.new(1, 2000, 10)
      car2 = Car.new(2, 3000, 15)

      transformer = CarsAndRentalsTransformer.new

      # When
      result = transformer.get_item([car1, car2], 2)

      # Then
      assert_equal car2, result
    end
  end

end