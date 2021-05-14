use Mix.Config

config :cybersource_sdk,
  endpoint: "http://ics2wstest.ic3.com/commerce/1.x/transactionProcessor/CyberSourceTransaction_1.142.wsdl",
  merchant: %{
    id: "xptoid123",
    transaction_key: "Base64EncodedKey==",
    currency: "USD"
  },
  debug: true
