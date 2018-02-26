# Purpose

This is an analysis of the feature parity between this project and the
[braintree\_ruby](https://github.com/braintree/braintree_ruby) project. The
eventual goal is to achieve complete feature parity with braintree\_ruby and
maintain that parity over time.

# Features

## Invocables

These are the classes that a client invokes to take an action against the
Braintree API. These classes follow a specific form:

* Invocable class which maps to a specific API entity
* Class methods on that class which map to entity methods on a gateway singleton
* A "gateway" singleton for each invocable which maps methods into API calls
* Class methods return an object of that class
* Objects of that class have methods mapping to the data structures from the API
* Complex data structure elements map to objects of their own

| Invocable | Method | Deprecated ? | In Perl? | Equivalent? |
| ---       | ---    | ---      | ---         | ---         |
| AddOn | all | | Yes | Yes |
| Address | create | | Yes | No |
| Address | delete | | Yes | No |
| Address | find | | Yes | No |
| Address | update | | Yes | No |
| ApplePay | register\_domain | | Yes | |
| ApplePay | unregister\_domain | | Yes | |
| ApplePay | registered\_domains | | Yes | |
| ClientToken | generate | | Yes | No |
| CreditCard | create | | Yes | No |
| CreditCard | create\_credit\_card\_url | Yes | No | |
| CreditCard | create\_from\_transparent\_redirect | Yes | No | |
| CreditCard | credit | | Yes | |
| CreditCard | delete | | Yes | Yes |
| CreditCard | expired | | Yes | expired\_cards() in Perl |
| CreditCard | expiring\_between | | Yes | |
| CreditCard | find | | Yes | |
| CreditCard | from\_nonce | | Yes | |
| CreditCard | grant | Yes | No | |
| CreditCard | sale | | Yes | |
| CreditCard | update | | Yes | |
| CreditCard | update\_from\_transparent\_redirect | Yes | No | |
| CreditCard | update\_credit\_card\_url | Yes | No | |
| CreditCardVerification | all | ??? | Yes | |
| CreditCardVerification | find | | Yes | |
| CreditCardVerification | search | | Yes | |
| CreditCardVerification | create | | Yes | |
| Customer | all | | Yes | |
| Customer | create | | Yes | |
| Customer | create\_customer\_url | Yes | No | |
| Customer | create\_from\_transparent\_redirect | Yes | No | |
| Customer | credit | | Yes | |
| Customer | delete | | Yes | |
| Customer | find | | Yes | |
| Customer | sale | | Yes | |
| Customer | search | | Yes | |
| Customer | transactions | | Yes | |
| Customer | update | | Yes | |
| Customer | update\_customer\_url | Yes | No | |
| Customer | update\_from\_transparent\_redirect | Yes | No | |
| Discount | all | | Yes | Yes |
| Dispute | accept | | Yes | |
| Dispute | add\_file\_evidence | | Yes | |
| Dispute | add\_text\_evidence | | Yes | |
| Dispute | finalize | | Yes | |
| Dispute | find | | Yes | |
| Dispute | remove\_evidence | | Yes | |
| Dispute | search | | Yes | |
| DocumentUpload | create | | Yes | |
| EuropeBankAccount | find | | Yes | |
| IdealPayment | find | | Yes | |
| IdealPayment | sale | | Yes | |
| Merchant | provision\_raw\_apple\_pay | | No | |
| MerchantAccount | all | ??? | Yes | |
| MerchantAccount | create | | Yes | |
| MerchantAccount | find | | Yes | |
| MerchantAccount | update | | Yes | |
| PaymentMethod | create | | Yes | |
| PaymentMethod | find | | Yes | |
| PaymentMethod | update | | Yes | |
| PaymentMethod | delete | | Yes | |
| PaymentMethod | grant | | Yes | |
| PaymentMethod | revoke | | Yes | |
| PaymentMethodNonce | create | | Yes | |
| PaymentMethodNonce | find | | Yes | |
| PayPalAccount | create | | Yes | |
| PayPalAccount | find | | Yes | |
| PayPalAccount | update | | Yes | |
| PayPalAccount | delete | | Yes | |
| PayPalAccount | sale | | Yes | |
| Plan | all | | Yes | |
| SettlementBatchSummary | generate | | Yes | |
| Subscription | all | ??? | Yes | |
| Subscription | cancel | | Yes | |
| Subscription | create | | Yes | |
| Subscription | find | | Yes | |
| Subscription | retry\_charge | | Yes | |
| Subscription | search | | Yes | |
| Subscription | update | | Yes | |
| Transaction | all | ??? | Yes | |
| Transaction | create | | Yes | |
| Transaction | cancel\_release | | Yes | |
| Transaction | clone\_transaction | | Yes | |
| Transaction | create\_from\_transparent\_redirect | Yes | No | |
| Transaction | create\_transaction\_url | Yes | No | |
| Transaction | credit | | Yes | |
| Transaction | find | | Yes | |
| Transaction | hold\_in\_escrow | | Yes | |
| Transaction | refund | | Yes | |
| Transaction | sale | | Yes | |
| Transaction | search | | Yes | |
| Transaction | release\_from\_escrow | | Yes | |
| Transaction | submit\_for\_settlement | | Yes | |
| Transaction | update\_details | | Yes | |
| Transaction | submit\_for\_partial\_settlement | | Yes | |
| Transaction | void | | Yes | |
| TransparentRedirect | confirm | | Yes | |
| TransparentRedirect | create\_credit\_card\_data | | Yes | |
| TransparentRedirect | create\_customer\_data | | Yes | |
| TransparentRedirect | transaction\_data | | Yes | |
| TransparentRedirect | update\_credit\_card\_data | | Yes | |
| TransparentRedirect | update\_customer\_data | | Yes | |
| TransparentRedirect | url | | Yes | |
| UsBankAccount | find | | Yes | |
| UsBankAccount | sale | | Yes | |
| WebhookNotification | parse | | Yes | |
| WebhookNotification | verify | | Yes | |
| WebhookTesting | sample\_notification | | Yes | |
