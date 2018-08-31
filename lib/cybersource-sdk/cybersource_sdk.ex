defmodule CyberSourceSDK do
  @moduledoc """
  This CyberSource module communicates with the Simple Order API
  service (SOAP) of CyberSource.
  """

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(CyberSourceSDK.Client, [])
    ]

    opts = [strategy: :one_for_one, name: CyberSourceSDK.Supervisor]

    Supervisor.start_link(children, opts)
  end

  @doc """
  Send an authorization request, making sure that the user have the necessary
  amount of money in his/her account.

  ## Parameters

  - price: Float that represents the price to be charged to the user.
  - merchant_reference_code: String that represents the order. Normally you should pass an unique identifier like `order_id`.
  - card_type: String with the name of card type, like VISA, MASTERCARD, etc.
  - encrypted_payment: String that must be in Base64 received by Apple/Android payment system.
  - bill_to: Structure generated by `CyberSourceSDK.bill_to()`. (Optional)
  - worker: Atom with name of the structure in configurations to be used. (Optional)

  """
  @spec authorize(float(), String.t(), String.t(), String.t(), list(String.t()), atom()) ::
          {:ok} | {:error, atom()} | {:error, String.t()}
  def authorize(
        price,
        merchant_reference_code,
        card_type,
        encrypted_payment,
        bill_to \\ [],
        worker \\ :merchant
      ) do
    CyberSourceSDK.Client.authorize(
      price,
      merchant_reference_code,
      card_type,
      encrypted_payment,
      bill_to,
      worker
    )
  end

  @doc """
  Send a capture request to charge the user account.
  """
  @spec capture(String.t(), String.t(), list(), atom()) ::
          {:ok} | {:error, atom()} | {:error, String.t()}
  def capture(order_id, request_id, items \\ [], worker \\ :merchant) do
    CyberSourceSDK.Client.capture(order_id, request_id, items, worker)
  end

  @doc """
  Send a refund request o remove the hold on user money.
  """
  @spec refund(String.t(), String.t(), list(), atom()) ::
          {:ok} | {:error, atom()} | {:error, String.t()}
  def refund(order_id, request_id, items \\ [], worker \\ :merchant) do
    CyberSourceSDK.Client.refund(order_id, request_id, items, worker)
  end

  @doc """
  Pay with Android Pay request
  """
  @spec pay_with_android_pay(
          float(),
          String.t(),
          String.t(),
          String.t(),
          list(String.t()),
          atom()
        ) :: {:ok} | {:error, atom()} | {:error, String.t()}
  def pay_with_android_pay(
        price,
        merchant_reference_code,
        card_type,
        encrypted_payment,
        bill_to \\ [],
        worker \\ :merchant
      ) do
    CyberSourceSDK.Client.pay_with_android_pay(
      price,
      merchant_reference_code,
      card_type,
      encrypted_payment,
      bill_to,
      worker
    )
  end

  @doc """
  Pay with Apple Pay request
  """
  @spec pay_with_apple_pay(float(), String.t(), String.t(), String.t(), list(String.t()), atom()) ::
          {:ok} | {:error, atom()} | {:error, String.t()}
  def pay_with_apple_pay(
        price,
        merchant_reference_code,
        card_type,
        encrypted_payment,
        bill_to \\ [],
        worker \\ :merchant
      ) do
    CyberSourceSDK.Client.pay_with_apple_pay(
      price,
      merchant_reference_code,
      card_type,
      encrypted_payment,
      bill_to,
      worker
    )
  end

  @doc """
  Generate BillTo object to replace parameters in request XML

  ## Examples

      iex> CyberSourceSDK.bill_to("John", "Doe", "Main Street", "2 Left", "New York", "USA", "john@example.com")
      [first_name: "John", last_name: "Doe", street1: "Main Street", street2: "2 Left", city: "New York", country: "USA", email: "john@example.com"]
  """
  @spec bill_to(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        ) :: list(String.t())
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
