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
      post_code: "12345",
      state: "NY",
      country: "USA",
      email: "john@example.com"
    ]

		parameters = CyberSourceSDK.bill_to("John", "Doe", "Maryland Street", "34", "New York", "12345", "NY", "USA", "john@example.com")

		assert expected_parameters == parameters
	end
end
