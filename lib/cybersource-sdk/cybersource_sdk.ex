defmodule CyberSourceSDK do
  @moduledoc """
  This CyberSource module deals with the communication with the Simple Order API
  service (SOAP) of CyberSource.
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(CyberSourceSDK.Client, []),
    ]
    opts = [strategy: :one_for_one, name: CyberSourceSDK.Supervisor]

    Supervisor.start_link(children, opts)
  end

  def authorize(price, merchant_reference_code, card_type, encrypted_payment, bill_to \\ [], worker \\ :merchant) do
    CyberSourceSDK.Client.authorize(price, merchant_reference_code, card_type, encrypted_payment, bill_to, worker)
  end

  def capture(order_id, request_id, items \\ [], worker \\ :merchant) do
    CyberSourceSDK.Client.capture(order_id, request_id, items, worker)
  end

  def refund(order_id, request_id, items \\ [], worker \\ :merchant) do
    CyberSourceSDK.Client.refund(order_id, request_id, items, worker)
  end

  def pay_with_android_pay(price, merchant_reference_code, card_type, encrypted_payment, bill_to \\ [], worker \\ :merchant) do
    CyberSourceSDK.Client.pay_with_android_pay(price, merchant_reference_code, card_type, encrypted_payment, bill_to, worker)
  end

  def pay_with_apple_pay(price, merchant_reference_code, card_type, encrypted_payment, request_id, bill_to \\ [], worker \\ :merchant) do
    CyberSourceSDK.Client.pay_with_apple_pay(price, merchant_reference_code, card_type, encrypted_payment, request_id, bill_to, worker)
  end

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
