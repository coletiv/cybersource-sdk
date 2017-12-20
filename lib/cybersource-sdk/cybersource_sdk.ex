defmodule CyberSourceSDK do
  @moduledoc """
  This CyberSource module deals with the communication with the Simple Order API
  service (SOAP) of CyberSource.
  """

  @doc """
  Generate BillTo object to replace parameters in request XML
  """
  def bill_to(first_name, last_name, street1, street2, city, country, email) do
    [
      first_name: first_name,
      last_name: last_name,
      street1: street1,
      street2: street2,
      city: city,
      country: country,
      email: email
    ]
  end
end
