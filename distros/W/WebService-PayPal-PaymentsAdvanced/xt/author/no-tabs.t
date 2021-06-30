use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'bin/mock-payflow-link',
    'bin/mock-payflow-pro',
    'lib/WebService/PayPal/PaymentsAdvanced.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Error/Authentication.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Error/Generic.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Error/HTTP.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Error/HostedForm.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Error/IPVerification.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Error/Role/HasHTTPResponse.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Mocker.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Mocker/Helper.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Mocker/PayflowLink.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Mocker/PayflowPro.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Mocker/SilentPOST.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Authorization.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Authorization/CreditCard.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Authorization/PayPal.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Capture.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Credit.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/FromHTTP.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/FromRedirect.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/FromSilentPOST.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/FromSilentPOST/CreditCard.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/FromSilentPOST/PayPal.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Inquiry.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Inquiry/CreditCard.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Inquiry/PayPal.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Sale.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Sale/CreditCard.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Sale/PayPal.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/SecureToken.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Response/Void.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Role/ClassFor.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Role/HasCreditCard.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Role/HasMessage.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Role/HasParams.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Role/HasPayPal.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Role/HasTender.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Role/HasTokens.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Role/HasTransactionTime.pm',
    'lib/WebService/PayPal/PaymentsAdvanced/Role/HasUA.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/PaymentsAdvanced-live.t',
    't/PaymentsAdvanced.t',
    't/PaymentsAdvanced/Mocker.t',
    't/PaymentsAdvanced/Mocker/SilentPOST.t',
    't/PaymentsAdvanced/Response.t',
    't/PaymentsAdvanced/Response/FromHTTP.t',
    't/PaymentsAdvanced/Response/FromRedirect.t',
    't/PaymentsAdvanced/Response/FromSilentPOST.t',
    't/PaymentsAdvanced/Response/FromSilentPOST/CreditCard.t',
    't/PaymentsAdvanced/Response/FromSilentPOST/PayPal.t',
    't/PaymentsAdvanced/Response/SecureToken.t',
    't/lib/Secret.pm',
    't/lib/Util.pm',
    't/test-data/hosted-form-with-error.html',
    't/test-data/hosted-form.html',
    't/test-data/sample-config.pl'
);

notabs_ok($_) foreach @files;
done_testing;
