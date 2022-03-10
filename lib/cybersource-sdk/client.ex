defmodule CyberSourceSDK.Client do
  @moduledoc """
  This Client module handle all HTTPS requests to the CyberSource server. It
  takes some parameters and convert to HTTPS requests.

  It support the following payments:
  * Android Pay
  * Apple Pay

  It supports the following requests:
  * Authorization
  * Capture
  * Refund
  """

  alias CyberSourceSDK.Logger

  @response_codes %{
    100 => "Successful transaction",
    101 => "Request is missing one or more required fields",
    102 => "One or more fields contains invalid data",
    150 => "General failure",
    151 => "The request was received but a server time-out occurred",
    152 => "The request was received, but a service timed out",
    200 =>
      "The authorization request was approved by the issuing bank but declined by CyberSource because it did not pass the AVS check",
    201 => "The issuing bank has questions about the request",
    202 => "Expired card",
    203 => "General decline of the card",
    204 => "Insufficient funds in the account",
    205 => "Stolen or lost card",
    207 => "Issuing bank unavailable",
    208 => "Inactive card or card not authorized for card-not-present transactions",
    209 => "American Express Card Identifiction Digits (CID) did not match",
    210 => "The card has reached the credit limit",
    211 => "Invalid card verification number",
    221 => "The customer matched an entry on the processor's negative file",
    230 =>
      "The authorization request was approved by the issuing bank but declined by CyberSource because it did not pass the card verification check",
    231 => "Invalid account number",
    232 => "The card type is not accepted by the payment processor",
    233 => "General decline by the processor",
    234 => "A problem exists with your CyberSource merchant configuration",
    235 => "The requested amount exceeds the originally authorized amount",
    236 => "Processor failure",
    237 => "The authorization has already been reversed",
    238 => "The authorization has already been captured",
    239 => "The requested transaction amount must match the previous transaction amount",
    240 => "The card type sent is invalid or does not correlate with the credit card number",
    241 => "The request ID is invalid",
    242 => "You requested a capture, but there is no corresponding, unused authorization record.",
    243 => "The transaction has already been settled or reversed",
    244 => "The bank account number failed the validation check",
    246 =>
      "The capture or credit is not voidable because the capture or credit information has already been submitted to your processor",
    247 => "You requested a credit for a capture that was previously voided",
    250 => "The request was received, but a time-out occurred with the payment processor",
    254 => "Your CyberSource account is prohibited from processing stand-alone refunds",
    255 =>
      "Your CyberSource account is not configured to process the service in the country you specified"
  }

  import SweetXml

  alias CyberSourceSDK.Helper

  use GenServer

  def init(args) do
    {:ok, args}
  end

  def start_link do
    GenServer.start_link(__MODULE__, {}, name: :cybersource_sdk_client)
  end

  @doc """
  Create an authorization payment

  For a normal account, bill_to is mandatory. If you ask CyberSource for a
  relaxed AVS check, bill_to can be optional.

  ## Parameters

    - price: Float that represents the price to be charged to the user.
    - merchant_reference_code: String that represents the order. Normally you should pass an unique identifier like `order_id`.
    - card_type: String with the name of card type, like VISA, MASTERCARD, etc.
    - encrypted_payment: String that must be in Base64 received by Apple/Android payment system.
    - bill_to: Structure generated by `CyberSourceSDK.bill_to()`. (Optional)
    - worker: Atom with name of the structure in configurations to be use. (Optional)

  ## Example

  Without `bill_to` and `worker` parameters

  ```
  authorize(32.0, "1234", "VISA", "oJ8IOx6SA9HNncxzpS9akm32n+DSAJH==")
  ```

  With `bill_to` parameter

  ```
  bill_to = CyberSourceSDK.bill_to("John", "Doe", "Marylane Street", "34", "New York", "Hong Kong", "john@example.com")
  authorize(32.0, "1234", "VISA", "oJ8IOx6SA9HNncxzpS9akm32n+DSAJH==", bill_to)
  ```

  """
  def authorize(
        price,
        merchant_reference_code,
        card_type,
        encrypted_payment,
        bill_to \\ [],
        worker \\ :merchant
      )

  def authorize(price, merchant_reference_code, card_type, encrypted_payment, bill_to, worker)
      when is_float(price) do
    case validate_merchant_reference_code(merchant_reference_code) do
      {:error, reason} ->
        {:error, reason}

      merchant_reference_code_validated ->
        case Helper.check_payment_type(encrypted_payment) do
          {:ok, :apple_pay} ->
            pay_with_apple_pay(
              price,
              merchant_reference_code_validated,
              card_type,
              encrypted_payment,
              bill_to,
              worker
            )

          {:ok, :android_pay} ->
            pay_with_android_pay(
              price,
              merchant_reference_code_validated,
              card_type,
              encrypted_payment,
              bill_to,
              worker
            )

          {:error, reason} ->
            {:error, reason}
        end
    end
  end

  def authorize(_, _, _, _, _, _) do
    {:error, :price_needs_to_be_float}
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
  def create_credit_card_token(
        merchant_reference_code,
        credit_card,
        bill_to,
        worker \\ :merchant
      )

  def create_credit_card_token(merchant_reference_code, credit_card, bill_to, worker) do
    Logger.info("Creating CC token")

    case validate_merchant_reference_code(merchant_reference_code) do
      {:error, reason} ->
        Logger.error("Coundn't validate merchant reference code #{inspect(reason)}")
        {:error, reason}

      merchant_reference_code_validated ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            CyberSourceSDK.Client.get_configuration_params(worker) ++
              credit_card ++ bill_to ++ [reference_id: merchant_reference_code_validated]

          EEx.eval_file(get_template("credit_card_create.xml"), assigns: replace_params) |> call()
        else
          Helper.invalid_merchant_configuration()
        end
    end
  end

  @doc """
  Update a credit card

  ## Example

  ```
  bill_to = CyberSourceSDK.bill_to(nil, nil, nil, nil, nil, nil, nil, nil, "john@otherexample.com") # can also be nil
  credit_card = CyberSourceSDK.credit_card(nil, "12", "2024", nil) # can also be nil
  update_credit_card("1234", "XXXXXXXX", credit_card, bill_to)
  ```
  """
  def update_credit_card(
        merchant_reference_code,
        token,
        credit_card,
        bill_to,
        worker \\ :merchant
      )

  def update_credit_card(merchant_reference_code, token, credit_card, bill_to, worker) do
    credit_card =
      if is_nil(credit_card), do: CyberSourceSDK.credit_card(nil, nil, nil), else: credit_card

    bill_to =
      if is_nil(bill_to),
        do: CyberSourceSDK.bill_to(nil, nil, nil, nil, nil, nil, nil, nil, nil),
        else: bill_to

    case validate_merchant_reference_code(merchant_reference_code) do
      {:error, reason} ->
        {:error, reason}

      merchant_reference_code_validated ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            CyberSourceSDK.Client.get_configuration_params(worker) ++
              credit_card ++
              bill_to ++ [reference_id: merchant_reference_code_validated, token: token]

          EEx.eval_file(get_template("credit_card_update.xml"), assigns: replace_params) |> call()
        else
          Helper.invalid_merchant_configuration()
        end
    end
  end

  @doc """
  Retrieve a credit card by reference code and token

  ## Example

  ```
  retrieve_credit_card("1234", "XXXXXXXXXXXXX")
  ```
  """
  def retrieve_credit_card(
        merchant_reference_code,
        token,
        worker \\ :merchant
      )

  def retrieve_credit_card(merchant_reference_code, token, worker) do
    case validate_merchant_reference_code(merchant_reference_code) do
      {:error, reason} ->
        {:error, reason}

      merchant_reference_code_validated ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            CyberSourceSDK.Client.get_configuration_params(worker) ++
              [reference_id: merchant_reference_code_validated, token: token]

          EEx.eval_file(get_template("credit_card_retrieve.xml"), assigns: replace_params)
          |> call()
        else
          Helper.invalid_merchant_configuration()
        end
    end
  end

  @doc """
  Delete a credit card by reference code and token

  ## Example

  ```
  delete_credit_card("1234", "XXXXXXXXXXXXX")
  ```
  """
  def delete_credit_card(
        merchant_reference_code,
        token,
        worker \\ :merchant
      )

  def delete_credit_card(merchant_reference_code, token, worker) do
    case validate_merchant_reference_code(merchant_reference_code) do
      {:error, reason} ->
        {:error, reason}

      merchant_reference_code_validated ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            CyberSourceSDK.Client.get_configuration_params(worker) ++
              [reference_id: merchant_reference_code_validated, token: token]

          EEx.eval_file(get_template("credit_card_delete.xml"), assigns: replace_params) |> call()
        else
          Helper.invalid_merchant_configuration()
        end
    end
  end

  @doc """
  Charge a credit card by token

  ## Example

  ```
  charge_credit_card(10.00, "1234", "XXXXXXXXXXXXX")
  ```
  """
  def charge_credit_card(
        price,
        merchant_reference_code,
        token,
        worker \\ :merchant
      )

  def charge_credit_card(price, merchant_reference_code, token, worker) do
    case validate_merchant_reference_code(merchant_reference_code) do
      {:error, reason} ->
        {:error, reason}

      merchant_reference_code_validated ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            CyberSourceSDK.Client.get_configuration_params(worker) ++
              [reference_id: merchant_reference_code_validated, token: token, price: price]

          EEx.eval_file(get_template("credit_card_charge.xml"), assigns: replace_params) |> call()
        else
          Helper.invalid_merchant_configuration()
        end
    end
  end

  @doc """
  Authorise a credit card by token

  ## Example

  ```
  auth_credit_card(10.00, "1234", "XXXXXXXXXXXXX")
  ```
  """
  def auth_credit_card(
        price,
        merchant_reference_code,
        token,
        worker \\ :merchant
      )

  def auth_credit_card(price, merchant_reference_code, token, worker) do
    case validate_merchant_reference_code(merchant_reference_code) do
      {:error, reason} ->
        {:error, reason}

      merchant_reference_code_validated ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            CyberSourceSDK.Client.get_configuration_params(worker) ++
              [reference_id: merchant_reference_code_validated, token: token, price: price]

          EEx.eval_file(get_template("credit_card_auth.xml"), assigns: replace_params) |> call()
        else
          Helper.invalid_merchant_configuration()
        end
    end
  end

  @doc """
  Capture authorization on user credit card

  ## Parameters
  - order_id: Unique number to identify the purchase.
  - request_params: Base64 of a JSON with `request_id` and `request_token` from authorization request.
  - items: An array of map containing the following values: `id`, `unit_price` and `quantity`. Example: ```%{id: id, unit_price: unit_price, quantity: quantity}```
  - worker: Merchant atom to use (setup in configurations).

  ## Result
  On successful return the result will be:

  ```
  {:ok, object}
  ```

  """
  def capture(order_id, request_params, items \\ [], worker \\ :merchant) do
    case Helper.json_from_base64(request_params) do
      {:ok, %{request_id: request_id, request_token: _request_token}} ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            get_configuration_params(worker) ++
              [request_id: request_id, reference_id: order_id] ++ [items: items]

          EEx.eval_file(get_template("capture_request.xml"), assigns: replace_params)
          |> call
        else
          Helper.invalid_merchant_configuration()
        end

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Remove authorization on user credit card

  ## Parameters

  - order_id: Unique number to identify the purchase.
  - amount: Price (value) to refund.
  - request_params: Base64 of a JSON with `request_id` and `request_token` from authorization request.
  - items: An array of map containing the following values: `id`, `unit_price` and `quantity`. Example: ```%{id: id, unit_price: unit_price, quantity: quantity}```
  - worker: Merchant atom to use (setup in configurations)

  ## Example

  ```
  refund("1234", 23435465442432, items)
  ```
  """
  def refund(order_id, amount, request_params, items \\ [], worker \\ :merchant) do
    case Helper.json_from_base64(request_params) do
      {:ok, %{request_id: request_id, request_token: _request_token}} ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            get_configuration_params(worker) ++
              [request_id: request_id, reference_id: order_id, total_amount: amount] ++
              [items: items]

          EEx.eval_file(get_template("refund_request.xml"), assigns: replace_params)
          |> call
        else
          Helper.invalid_merchant_configuration()
        end

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  A void cancels a capture or credit request that you submitted to CyberSource. A
  transaction can be voided only when CyberSource has not already submitted the capture
  or credit request to your processor. CyberSource usually submits capture and credit
  requests to your processor once a day, so your window for successfully voiding a capture
  or credit request is small. CyberSource declines your void request when the capture or
  credit request has already been sent to the processor
  """
  def void(order_id, request_params, worker \\ :merchant) do
    case Helper.json_from_base64(request_params) do
      {:ok, %{request_id: request_id, request_token: _request_token}} ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            get_configuration_params(worker) ++ [request_id: request_id, reference_id: order_id]

          EEx.eval_file(get_template("void_request.xml"), assigns: replace_params)
          |> call
        else
          Helper.invalid_merchant_configuration()
        end

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  When your request for a credit is successful, the issuing bank for the credit
  card takes money out of your merchant bank account and returns it to the customer.
  It usually takes two to four days for your acquiring bank to transfer funds
  from your merchant bank account.
  """
  def credit(order_id, amount, reason, request_params, worker \\ :merchant) do
    case Helper.json_from_base64(request_params) do
      {:ok, %{request_id: request_id, request_token: _request_token}} ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            get_configuration_params(worker) ++
              [
                request_id: request_id,
                reference_id: order_id,
                total_amount: amount,
                refund_reason: reason
              ]

          EEx.eval_file(get_template("credit_request.xml"), assigns: replace_params)
          |> call
        else
          Helper.invalid_merchant_configuration()
        end

      {:error, message} ->
        {:error, message}
    end
  end

  @doc """
  Make a request to pay with Android Pay

  Returns `{:ok, response_object}` , `{:error, :card_type_not_found` or
   `{:error, response_code}`
  """
  def pay_with_android_pay(
        price,
        merchant_reference_code,
        card_type,
        encrypted_payment,
        bill_to \\ [],
        worker \\ :merchant
      ) do
    case get_card_type(card_type) do
      nil ->
        {:error, :card_type_not_found}

      card_type ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            get_configuration_params(worker) ++
              get_payment_params(merchant_reference_code, price, encrypted_payment, card_type) ++
              bill_to

          EEx.eval_file(get_template("android_pay_request.xml"), assigns: replace_params)
          |> call
        else
          Helper.invalid_merchant_configuration()
        end
    end
  end

  @doc """
  Make a request to pay with Apple Pay

  Returns `{:ok, response_object}` , `{:error, :card_type_not_found` or
   `{:error, response_code}`
  """
  def pay_with_apple_pay(
        price,
        merchant_reference_code,
        card_type,
        encrypted_payment,
        bill_to \\ [],
        worker \\ :merchant
      ) do
    case get_card_type(card_type) do
      nil ->
        {:error, :card_type_not_found}

      card_type ->
        merchant_configuration = get_configuration_params(worker)

        if length(merchant_configuration) > 0 do
          replace_params =
            CyberSourceSDK.Client.get_configuration_params(worker) ++
              CyberSourceSDK.Client.get_payment_params(
                merchant_reference_code,
                price,
                encrypted_payment,
                card_type
              ) ++ bill_to

          EEx.eval_file(get_template("apple_pay_request.xml"), assigns: replace_params)
          |> call()
        else
          Helper.invalid_merchant_configuration()
        end
    end
  end

  # Define path of request templates
  defp get_template(filename) do
    Path.join(__DIR__, "/requests/" <> filename <> ".eex")
    Path.join(:code.priv_dir(:cybersource_sdk), "/requests/" <> filename <> ".eex")
  end

  # Get Payment parameters
  @spec get_payment_params(String.t(), float(), String.t(), String.t()) :: list()
  def get_payment_params(order_id, price, encrypted_token, card_type) do
    [
      reference_id: order_id,
      total_amount: price,
      encrypted_payment_data: encrypted_token,
      card_type: card_type
    ]
  end

  @spec get_card_type(String.t()) :: String.t() | nil
  def get_card_type(card_type) do
    case card_type do
      "VISA" -> "001"
      "MASTERCARD" -> "002"
      "AMEX" -> "003"
      "DISCOVER" -> "004"
      "JCB" -> "007"
      _ -> nil
    end
  end

  @spec get_configuration_params(atom()) :: list()
  def get_configuration_params(worker) do
    merchant_configuration = Application.get_env(:cybersource_sdk, worker)

    if !is_nil(merchant_configuration) do
      merchant_configuration = merchant_configuration |> Enum.into(%{})

      [
        merchant_id:
          Map.get(merchant_configuration, :id) || System.get_env("CYBERSOURCE_MERCHANT_ID"),
        transaction_key:
          Map.get(merchant_configuration, :transaction_key) ||
            System.get_env("CYBERSOURCE_TRANSACTION_KEY"),
        currency:
          Map.get(merchant_configuration, :currency) || System.get_env("CYBERSOURCE_CURRENCY"),
        client_library: "CyberSourceSDK Elixir #{Application.spec(:cybersource_sdk, :vsn)}"
      ]
    else
      []
    end
  end

  # Make HTTPS request
  @spec call(String.t()) :: {:ok, map()} | {:error, String.t()} | {:error, :unknown_response}
  defp call(xml_body) do
    endpoint =
      Application.get_env(:cybersource_sdk, :endpoint) || System.get_env("CYBERSOURCE_ENDPOINT")

    timeout = Application.get_env(:cybersource_sdk, :timeout, 60_000)

    case HTTPoison.post(
           endpoint,
           xml_body,
           [{"Content-Type", "application/xml"}],
           timeout: timeout,
           recv_timeout: timeout
         ) do
      {:ok, %HTTPoison.Response{body: response_body}} ->
        parse_response(response_body)
        |> handle_response

      {:error, %HTTPoison.Error{id: _, reason: reason}} = response ->
        Logger.error("Timeout: #{timeout}")
        Logger.error("#{inspect(response)}")
        {:error, reason}
    end
  end

  defp validate_merchant_reference_code(merchant_reference_code) do
    cond do
      String.valid?(merchant_reference_code) && String.length(merchant_reference_code) ->
        merchant_reference_code

      is_integer(merchant_reference_code) ->
        Integer.to_string(merchant_reference_code)

      true ->
        {:error, :invalid_order_id}
    end
  end

  # Parse response from CyberSource
  @spec parse_response(String.t()) :: map()
  def parse_response(xml) do
    xml
    |> xmap(
      merchantReferenceCode:
        ~x"//soap:Envelope/soap:Body/c:replyMessage/c:merchantReferenceCode/text()"os,
      requestID: ~x"//soap:Envelope/soap:Body/c:replyMessage/c:requestID/text()"oi,
      decision: ~x"//soap:Envelope/soap:Body/c:replyMessage/c:decision/text()"os,
      invalidField: ~x"//soap:Envelope/soap:Body/c:replyMessage/c:invalidField/text()"os,
      missingField: ~x"//soap:Envelope/soap:Body/c:replyMessage/c:missingField/text()"os,
      reasonCode: ~x"//soap:Envelope/soap:Body/c:replyMessage/c:reasonCode/text()"oi,
      requestToken: ~x"//soap:Envelope/soap:Body/c:replyMessage/c:requestToken/text()"os,
      ccAuthReply: [
        ~x".//c:ccAuthReply"o,
        reasonCode: ~x"./c:reasonCode/text()"i,
        amount: ~x"./c:amount/text()"of
      ],
      ccCaptureReply: [
        ~x".//c:ccCaptureReply"o,
        reasonCode: ~x"./c:reasonCode/text()"i,
        amount: ~x"./c:amount/text()"of,
        requestDateTime: ~x"./c:requestDateTime/text()"so,
        reconciliationID: ~x"./c:reconciliationID/text()"so
      ],
      ccAuthReversalReply: [
        ~x".//c:ccAuthReversalReply"o,
        reasonCode: ~x"./c:reasonCode/text()"i
      ],
      originalTransaction: [
        ~x".//c:originalTransaction"o,
        amount: ~x"./c:amount/text()"of,
        reasonCode: ~x"./c:reasonCode/text()"i
      ],
      voidReply: [
        ~x".//c:voidReply"o,
        reasonCode: ~x"./c:reasonCode/text()"i,
        amount: ~x"./c:amount/text()"of,
        requestDateTime: ~x"./c:requestDateTime/text()"so,
        currency: ~x"./c:currency/text()"so
      ],
      ccCreditReply: [
        ~x".//c:ccCreditReply"o,
        reasonCode: ~x"./c:reasonCode/text()"i,
        requestDateTime: ~x"./c:requestDateTime/text()"so,
        amount: ~x"./c:amount/text()"of,
        reconciliationID: ~x"./c:reconciliationID/text()"so,
        purchasingLevel3Enabled: ~x"./c:purchasingLevel3Enabled/text()"so,
        enhancedDataEnabled: ~x"./c:enhancedDataEnabled/text()"so,
        authorizationXID: ~x"./c:authorizationXID/text()"so,
        forwardCode: ~x"./c:forwardCode/text()"so,
        ownerMerchantID: ~x"./c:ownerMerchantID/text()"so,
        reconciliationReferenceNumber: ~x"./c:reconciliationReferenceNumber/text()"so
      ],
      paySubscriptionCreateReply: [
        ~x".//c:paySubscriptionCreateReply"o,
        reasonCode: ~x"./c:reasonCode/text()"i,
        subscriptionID: ~x"./c:subscriptionID/text()"i
      ],
      paySubscriptionUpdateReply: [
        ~x".//c:paySubscriptionUpdateReply"o,
        reasonCode: ~x"./c:reasonCode/text()"i,
        subscriptionID: ~x"./c:subscriptionID/text()"i
      ],
      paySubscriptionDeleteReply: [
        ~x".//c:paySubscriptionDeleteReply"o,
        reasonCode: ~x"./c:reasonCode/text()"i,
        subscriptionID: ~x"./c:subscriptionID/text()"i
      ],
      paySubscriptionRetrieveReply: [
        ~x".//c:paySubscriptionRetrieveReply"o,
        reasonCode: ~x"./c:reasonCode/text()"i,
        approvalRequired: ~x"./c:approvalRequired/text()"s,
        automaticRenew: ~x"./c:automaticRenew/text()"s,
        cardAccountNumber: ~x"./c:cardAccountNumber/text()"s,
        cardExpirationMonth: ~x"./c:cardExpirationMonth/text()"i,
        cardExpirationYear: ~x"./c:cardExpirationYear/text()"i,
        cardType: ~x"./c:cardType/text()"s,
        city: ~x"./c:city/text()"s,
        country: ~x"./c:country/text()"s,
        currency: ~x"./c:currency/text()"s,
        email: ~x"./c:email/text()"s,
        endDate: ~x"./c:endDate/text()"i,
        firstName: ~x"./c:firstName/text()"s,
        frequency: ~x"./c:frequency/text()"s,
        lastName: ~x"./c:lastName/text()"s,
        paymentMethod: ~x"./c:paymentMethod/text()"s,
        paymentsRemaining: ~x"./c:paymentsRemaining/text()"i,
        postalCode: ~x"./c:postalCode/text()"s,
        startDate: ~x"./c:startDate/text()"i,
        state: ~x"./c:state/text()"s,
        status: ~x"./c:status/text()"s,
        street1: ~x"./c:street1/text()"s,
        subscriptionID: ~x"./c:subscriptionID/text()"s,
        totalPayments: ~x"./c:totalPayments/text()"i,
        ownerMerchantID: ~x"./c:ownerMerchantID/text()"s
      ],
      fault: [
        ~x"//soap:Envelope/soap:Body/soap:Fault"o,
        faultCode: ~x"./faultcode/text()"s,
        faultString: ~x"./faultstring/text()"s
      ]
    )
  end

  @spec handle_response(map()) ::
          {:ok, map()} | {:error, String.t(), String.t()} | {:error, :unknown_response}
  defp handle_response(response) do
    cond do
      response.decision != "" ->
        case response.decision do
          "ACCEPT" ->
            {:ok, response}

          "REJECT" ->
            {:error, response.reasonCode, reason_from_code(response.reasonCode), response}

          "ERROR" ->
            {:error, response.reasonCode, reason_from_code(response.reasonCode), response}
        end

      response.fault.faultCode != "" ->
        {:error, "#{response.fault.faultCode} - #{response.fault.faultString}"}

      true ->
        {:error, :unknown_response}
    end
  end

  defp reason_from_code(code) do
    @response_codes[code]
  end
end
