require 'csv'
require 'time'

require_relative 'passenger'
require_relative 'trip'
require_relative 'driver'

module RideShare
  class TripDispatcher
    attr_reader :drivers, :passengers, :trips

    def initialize(directory: './support')
      @passengers = Passenger.load_all(directory: directory)
      @trips = Trip.load_all(directory: directory)
      @drivers = Driver.load_all(directory: directory)
      connect_trips
    end

    def find_passenger(id)
      Passenger.validate_id(id)
      return @passengers.find { |passenger| passenger.id == id }
    end

    def find_driver(id)
      Driver.validate_id(id)
      return @drivers.find { |driver| driver.id == id}
    end

    def inspect
      # Make puts output more useful
      return "#<#{self.class.name}:0x#{object_id.to_s(16)} \
              #{trips.count} trips, \
              #{drivers.count} drivers, \
              #{passengers.count} passengers>"
    end

    def available_driver
      available_drivers = []
      @drivers.each do |driver|
        if driver.status == :AVAILABLE
          available_drivers << driver
        end
      end
      return available_drivers
    end

    def trip_id_generator
      return @trips.last.id.to_i + 1
    end

    def request_trip(passenger_id)
      driver = available_driver[0]
      passenger = find_passenger(passenger_id)

      if driver == nil
        raise ArgumentError.new("No available drivers")
      end

      new_trip = Trip.new(
          id: trip_id_generator,
          driver_id: driver.id,
          passenger_id: passenger_id,
          start_time: Time.now,
          )
      driver.make_unavailable

      new_trip.connect(passenger, driver)

      @trips << new_trip

      return new_trip
    end

    private

    def connect_trips
      @trips.each do |trip|
        passenger = find_passenger(trip.passenger_id)
        driver = find_driver(trip.driver_id)
        trip.connect(passenger, driver)
      end

      return trips
    end
  end
end
