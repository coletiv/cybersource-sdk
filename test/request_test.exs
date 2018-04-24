defmodule CyberSourceSDK.RequestTest do
  use ExUnit.Case, async: true

  setup do
    bypass = Bypass.open()

    :ok = Application.put_env(:cybersource_sdk, :endpoint, endpoint_url(bypass.port))

    {:ok, %{bypass: bypass}}
  end

  test "Invalid user credentials response handle", %{bypass: bypass} do
    {:ok, content_response} = File.read("test/requests/invalid_auth_response.xml")

    Bypass.expect(bypass, fn conn ->
      assert "/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.142.wsdl" ==
               "#{conn.request_path}"

      assert "POST" == conn.method
      Plug.Conn.resp(conn, 200, content_response)
    end)

    object = ~s({"header": "header", "signature": "signature"})
		bill_to = CyberSourceSDK.bill_to("John", "Doe", "Maryland Street", "34", "New York", "USA", "john@example.com")

    request_params = Base.encode64(object)

    response_object = CyberSourceSDK.Client.authorize(
      123.2,
      "1234",
      "VISA",
      request_params,
      bill_to)

    assert response_object == {:error,
      "wsse:FailedCheck - Security Data : UsernameToken authentication failed."}
  end

  defp endpoint_url(port), do: "http://localhost:#{port}/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.142.wsdl"
end
