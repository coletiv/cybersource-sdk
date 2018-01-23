# Cybersource SDK

[![Build Status](https://travis-ci.org/coletiv/cybersource-sdk.svg?branch=master)](https://travis-ci.org/coletiv/cybersource-sdk)
[![Hex.pm Version](http://img.shields.io/hexpm/v/cybersource_sdk.svg)](https://hex.pm/packages/cybersource_sdk)

This module handle CyberSource SOAP service for payments. I've tried to use [Detergentx](https://github.com/r-icarus/detergentex) Elixir wrapper to erlang module detergent without success. Also tried [Bet365 soap](https://github.com/bet365/soap/) module, with no luck.

This module only works for **Apple Pay** and **Android Pay**. Other systems will be added in the future.

It only supports 3 types of requests: Authorization, Capture and Refund.

## Usage

1. Add `cybersource_sdk` to your deps:

```
[
  ...
  {:cybersource_sdk, "~> 0.0.3"},
  ...
]
```

2. Add `cybersource_sdk` to the list of applications dependencies in your `mix.exs`.

```
def application do
  [applications: [..., :cybersource_sdk]]
end
```

3. Add configuration to your `prod.secret.exs` and/or `dev.secret.exs`.

Check [Configurations](#Configurations).

4. How to call it.

Check [Requests](#Requests).

## Configurations

You can update 4 parameters in configurations:

* **endpoint**: WSDL endpoint URL, you can check the most recent in `https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/`. Don't forget to only use the one with `.wsdl`.
* **merchant_id**: Your `merchant_id`, the same you use for login.
* **transaction_key**: This key can be generated in your [Business Center](https://ebctest.cybersource.com/ebctest/login/LoginProcess.do), under `Account Management` > `Transaction Security Keys` > `Security Keys for the SOAP Toolkit API`.
* **currency**: Value of the currency you are going to use. Example: `USD`, `EUR`, ...

```
config :cybersource_sdk,
  endpoint: "https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.142.wsdl",
  merchant: %{
    id: "my_company",
    transaction_key: "pdsamp9094m89njkndsa+32423lnksi0NBL32M90dan==",
    currency: "USD"
  }
```

You can add multiple merchants. You need to setup first in configurations like the following example:

```
config :cybersource_sdk,
  endpoint: "https://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.142.wsdl",
  merchant_apple_pay: %{
    id: "my_company_1",
    transaction_key: "pdsamp9094m89njkndsa+32423lnksi0NBL32M90dan==",
    currency: "USD"
  },
  merchant_android_pay: %{
    id: "my_company_2",
    transaction_key: "pdsamp9094m89njkndsa+32423lnksi0NBL32M90dan==",
    currency: "USD"
  }
```

After this, you need to send the `worker` merchant atom to the request.

## Requests

### Authorization

Check credit card funds, and hold the payment of the transaction until a capture or refund request is issued.

**Example**
```
bill_to = CyberSourceSDK.bill_to("John", "Doe", "Freedom Street", "3L 10001", "New York", "USA", "john.doe@example.com")
CyberSourceSDK.authorize(50, bill_to, "VISA", "3a9KSs98jDSAMsandsab8DSA+dk==", [], :merchant_android_pay)
```

### Capture

Complete the authorization request by finishing it with the capture request. All the funds of this transaction will be available in your account and charged to the user.

**Example**
```
items = [
  %{
    id: 0,
    unit_price: 12,
    quantity: 2
  }
]

CyberSourceSDK.capture("12345", request_id, items)
```

### Refund

Cancel the authorization request by letting CyberSource know that you don't want to charge the user.

**Example**
```
items = [
  %{
    id: 0,
    unit_price: 12,
    quantity: 2
  }
]

CyberSourceSDK.refund("12345", request_id, items)
```

## Response

Response to the request will be the following map:

```
merchantReferenceCode: "...",
requestID: ...,
decision: "...",
reasonCode: ...,
requestToken: "...",
ccAuthReply: [
  reasonCode: ....,
  amount: ...
],
ccCapctureReply: [
  reasonCode: ...,
  amount: ...
],
ccAuthReversalReply: [
  reasonCode: ...,
  amount: ...
]
```
