defmodule CyberSourceSDK do
  @moduledoc """
  This CyberSource module communicates with the Simple Order API
  service (SOAP) of CyberSource.
  """

  use Application

  alias CyberSourceSDK.Client
  alias CyberSourceSDK.Helper

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
  Create a credit card token

  ## Example

  ```
  bill_to = CyberSourceSDK.bill_to("John", "Doe", "Marylane Street", "34", "New York", "12345", "NY" "USA", "john@example.com")
  credit_card = CyberSourceSDK.credit_card("4111111111111111", "12", "2020", "001")
  create_credit_card_token("1234", credit_card, bill_to)
  ```
  """
  @spec create_credit_card_token(
        String.t(),
        keyword(),
        keyword(),
        atom()
      ) :: {:ok, map()} | {:error, atom()} | {:error, String.t()}
  def create_credit_card_token(merchant_reference_code, credit_card, bill_to, worker \\ :merchant) do
    Client.create_credit_card_token(merchant_reference_code, credit_card, bill_to, worker)
  end

  @doc """
  Retrieve a credit card by token + reference

  ## Example

  ```
  retrieve_credit_card("1234", "XXXXXXXXXXXXXXXX")
  ```
  """
  @spec retrieve_credit_card(
        String.t(),
        String.t(),
        atom()
      ) :: {:ok, map()} | {:error, atom()} | {:error, String.t()}
  def retrieve_credit_card(merchant_reference_code, token, worker \\ :merchant) do
    Client.retrieve_credit_card(merchant_reference_code, token, worker)
  end

  @doc """
  Generate BillTo object to replace parameters in request XML

  ## Examples

      iex> CyberSourceSDK.bill_to("John", "Doe", "Main Street", "2 Left", "New York", "12345", "NY", "USA", "john@example.com")
      [first_name: "John", last_name: "Doe", street1: "Main Street", street2: "2 Left", city: "New York", post_code: "12345", state: "NY", country: "USA", email: "john@example.com"]
  """
  @spec bill_to(
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t(),
          String.t()
        ) :: list(String.t())
  def bill_to(first_name, last_name, street1, street2, city, post_code, state, country, email) do
    [
      first_name: first_name,
      last_name: last_name,
      street1: street1,
      street2: street2,
      city: city,
      post_code: post_code,
      state: state,
      country: country,
      email: email
    ]
  end


  @doc """
  Generate creditCard object to replace parameters in request XML

  ## Examples

      iex> CyberSourceSDK.credit_card("4111111111111111", "12", "2020")
      [card_number: "4111111111111111", expiration_month: "12", expiration_year: "2020", card_type: "001"]
  """
  @spec credit_card(
          String.t(),
          String.t(),
          String.t()
        ) :: list(String.t())
  def credit_card(card_number, expiration_month, expiration_year) do
    [
      card_number: card_number,
      expiration_month: expiration_month,
      expiration_year: expiration_year,
      card_type: Client.get_card_type(Helper.card_type_from_number(card_number))
    ]
  end
end
