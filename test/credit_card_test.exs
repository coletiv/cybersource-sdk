defmodule CyberSourceSDK.CreditCardTest do
  use ExUnit.Case
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney


  setup_all do
    :ok
  end

  test "Can create a card token" do
    use_cassette "create card token" do
      bill_to = CyberSourceSDK.bill_to("John", "Doe", "Marylane Street", "34", "New York", "12345", "NY", "USA", "john@example.com")
      credit_card = CyberSourceSDK.credit_card("4111111111111111", "12", "2020")
      card = CyberSourceSDK.create_credit_card_token("123", credit_card, bill_to)

      assert card == {:ok,
        %{
          ccAuthReply: %{amount: 0.0, reasonCode: 100},
          ccAuthReversalReply: nil,
          ccCaptureReply: nil,
          ccCreditReply: nil,
          decision: "ACCEPT",
          fault: nil,
          merchantReferenceCode: "123",
          originalTransaction: nil,
          paySubscriptionCreateReply: %{reasonCode: 100, subscriptionID: 123456789},
          paySubscriptionDeleteReply: nil,
          paySubscriptionRetrieveReply: nil,
          paySubscriptionUpdateReply: nil,
          reasonCode: 100,
          requestID: 1234592242856049004012,
          requestToken: "ABCDEFGSTOog0ehNMRk3sABRRqAPeVGYCo1AHvHjPSAAA5DJpJli6+Bg4kCcmdRBo9CaYjJvYAAAAqgih",
          voidReply: nil
        }
      }
    end
  end

  test "Can retrieve a card by token" do
    use_cassette "retrieve card by token" do
      card = CyberSourceSDK.retrieve_credit_card("123", "234567891")

      assert card == {:ok,
        %{                                                                                                                                               
          ccAuthReply: nil,                                                                                                                              
          ccAuthReversalReply: nil,                                                                                                                      
          ccCaptureReply: nil,                                                                                                                           
          ccCreditReply: nil,                                                                                                                            
          decision: "ACCEPT",                                                                                                                            
          fault: nil,                                                                                                                                    
          merchantReferenceCode: "123",                                                                                                                  
          originalTransaction: nil,
          paySubscriptionCreateReply: nil,
          paySubscriptionDeleteReply: nil,
          paySubscriptionRetrieveReply: %{
            approvalRequired: "false",
            automaticRenew: "false",
            cardAccountNumber: "411111XXXXXX1111",
            cardExpirationMonth: 12,
            cardExpirationYear: 2020,
            cardType: "001",
            city: "New York",
            country: "US",
            currency: "USD",
            email: "john@example.com",
            endDate: 99991231,
            firstName: "JOHN",
            frequency: "on-demand",
            lastName: "DOE",
            ownerMerchantID: "MERCHANT_ID",
            paymentMethod: "credit card",
            paymentsRemaining: 0,
            postalCode: "12345",
            reasonCode: 100,
            startDate: 20200129,
            state: "NY",
            status: "CURRENT",
            street1: "Marylane Street",
            subscriptionID: "234567891",
            totalPayments: 0
          },
          paySubscriptionUpdateReply: nil,
          reasonCode: 100,
          requestID: 1234592252656050004012,
          requestToken: "ABCDEFGTOog0gv0J2mAsABQBUagD3lSppAAAchk0kyxdfAwcQA0A6EJa",
          voidReply: nil
        }
      }
    end
  end

  test "Can update a card" do
    use_cassette "update card" do
      bill_to = CyberSourceSDK.bill_to("Joe", "Bloggs", nil, nil, nil, nil, nil, nil, "joe@bloggs.com")
      credit_card = CyberSourceSDK.credit_card(nil, "12", "2021")
      {:ok, _card} = CyberSourceSDK.update_credit_card("123", "234567891", credit_card, bill_to)
      {:ok, card} = CyberSourceSDK.retrieve_credit_card("123", "234567891")

      card_details = card.paySubscriptionRetrieveReply

      assert card_details.firstName == "JOE"
      assert card_details.lastName == "BLOGGS"
      assert card_details.email == "joe@bloggs.com"
      assert card_details.cardExpirationMonth == 12
      assert card_details.cardExpirationYear == 2021
    end
  end

  test "Can charge a card" do
    use_cassette "charge card" do
      {:ok, charge} = CyberSourceSDK.charge_credit_card(10.10, "123", "234567891")

      assert charge == %{
        ccAuthReply: %{amount: 10.1, reasonCode: 100}, 
        ccAuthReversalReply: nil, 
        ccCaptureReply: %{amount: 10.1, reasonCode: 100, reconciliationID: "123456552IRLSV5JLP1DC", requestDateTime: "2020-01-28T11:13:24Z"}, 
        ccCreditReply: nil, 
        decision: "ACCEPT", 
        fault: nil, 
        merchantReferenceCode: "123", 
        originalTransaction: nil, 
        paySubscriptionCreateReply: nil, 
        paySubscriptionDeleteReply: nil, 
        paySubscriptionRetrieveReply: nil, 
        paySubscriptionUpdateReply: nil, 
        reasonCode: 100, 
        requestID: 1234500040956805804009, 
        requestToken: "ABCDEFGTOohQLmgdzm/pABQq3cuW7Bs1aspNKZTrNZUygxiQ1GoA98GZgKjUAe+DM9IFfkAOQyaSZYuvgYOIGBOTOohQLmgdzm/pAAAARhq0", 
        voidReply: nil
      }
    end
  end

  test "Can delete a card" do
    use_cassette "delete card" do
      {:ok, deleted_card} = CyberSourceSDK.delete_credit_card("123", "234567891")

      assert deleted_card == %{
        ccAuthReply: nil, 
        ccAuthReversalReply: nil, 
        ccCaptureReply: nil, 
        ccCreditReply: nil, 
        decision: "ACCEPT", 
        fault: nil, 
        merchantReferenceCode: "123", 
        originalTransaction: nil, 
        paySubscriptionCreateReply: nil, 
        paySubscriptionDeleteReply: %{reasonCode: 100, subscriptionID: 234567891}, 
        paySubscriptionRetrieveReply: nil, 
        paySubscriptionUpdateReply: nil, 
        reasonCode: 100, 
        requestID: 1234501006036850704009, 
        requestToken: "ABCDEFGTOohTnCRTD/6JABRRqAPfG6wAAchk0kyxdfAwcQAA5yXM", 
        voidReply: nil
      }
    end
  end
end
