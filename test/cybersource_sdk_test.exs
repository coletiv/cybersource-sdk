defmodule CyberSourceSDKTest do
	use ExUnit.Case, async: true
	doctest CyberSourceSDK
	doctest CyberSourceSDK.Helper

	test "Test bill_to generated parameters" do
		expected_parameters = [
      first_name: "John",
      last_name: "Doe",
      street1: "Maryland Street",
      street2: "34",
      city: "New York",
      country: "USA",
      email: "john@example.com"
    ]

		parameters = CyberSourceSDK.bill_to("John", "Doe", "Maryland Street", "34", "New York", "USA", "john@example.com")

		assert expected_parameters == parameters
	end
end
