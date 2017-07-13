use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/WebService/MinFraud.pm',
    'lib/WebService/MinFraud/Client.pm',
    'lib/WebService/MinFraud/Data/Rx/Type/CCToken.pm',
    'lib/WebService/MinFraud/Data/Rx/Type/CustomInputs.pm',
    'lib/WebService/MinFraud/Data/Rx/Type/DateTime/RFC3339.pm',
    'lib/WebService/MinFraud/Data/Rx/Type/Enum.pm',
    'lib/WebService/MinFraud/Data/Rx/Type/Hex32.pm',
    'lib/WebService/MinFraud/Data/Rx/Type/Hostname.pm',
    'lib/WebService/MinFraud/Data/Rx/Type/IPAddress.pm',
    'lib/WebService/MinFraud/Data/Rx/Type/WebURI.pm',
    'lib/WebService/MinFraud/Error/Generic.pm',
    'lib/WebService/MinFraud/Error/HTTP.pm',
    'lib/WebService/MinFraud/Error/WebService.pm',
    'lib/WebService/MinFraud/Example.pod',
    'lib/WebService/MinFraud/Model/Factors.pm',
    'lib/WebService/MinFraud/Model/Insights.pm',
    'lib/WebService/MinFraud/Model/Score.pm',
    'lib/WebService/MinFraud/Record/BillingAddress.pm',
    'lib/WebService/MinFraud/Record/Country.pm',
    'lib/WebService/MinFraud/Record/CreditCard.pm',
    'lib/WebService/MinFraud/Record/Device.pm',
    'lib/WebService/MinFraud/Record/Disposition.pm',
    'lib/WebService/MinFraud/Record/Email.pm',
    'lib/WebService/MinFraud/Record/IPAddress.pm',
    'lib/WebService/MinFraud/Record/Issuer.pm',
    'lib/WebService/MinFraud/Record/Location.pm',
    'lib/WebService/MinFraud/Record/ScoreIPAddress.pm',
    'lib/WebService/MinFraud/Record/ShippingAddress.pm',
    'lib/WebService/MinFraud/Record/Subscores.pm',
    'lib/WebService/MinFraud/Record/Warning.pm',
    'lib/WebService/MinFraud/Role/Data/Rx/Type.pm',
    'lib/WebService/MinFraud/Role/Error/HTTP.pm',
    'lib/WebService/MinFraud/Role/HasCommonAttributes.pm',
    'lib/WebService/MinFraud/Role/HasLocales.pm',
    'lib/WebService/MinFraud/Role/Model.pm',
    'lib/WebService/MinFraud/Role/Record/Address.pm',
    'lib/WebService/MinFraud/Role/Record/HasRisk.pm',
    'lib/WebService/MinFraud/Types.pm',
    'lib/WebService/MinFraud/Validator.pm',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/WebService/MinFraud/Client.t',
    't/WebService/MinFraud/Model/Factors.t',
    't/WebService/MinFraud/Model/Insights.t',
    't/WebService/MinFraud/Model/Score.t',
    't/WebService/MinFraud/Record/BillingAddress.t',
    't/WebService/MinFraud/Record/CreditCard.t',
    't/WebService/MinFraud/Record/Device.t',
    't/WebService/MinFraud/Record/Disposition.t',
    't/WebService/MinFraud/Record/Email.t',
    't/WebService/MinFraud/Record/Issuer.t',
    't/WebService/MinFraud/Record/ScoreIPAddress.t',
    't/WebService/MinFraud/Record/ShippingAddress.t',
    't/WebService/MinFraud/Record/Subscores.t',
    't/WebService/MinFraud/Record/Warning.t',
    't/WebService/MinFraud/Validator.t',
    't/data/factors-response.json',
    't/data/full-request.json',
    't/data/insights-response.json',
    't/data/score-response.json',
    't/lib/Test/WebService/MinFraud.pm'
);

notabs_ok($_) foreach @files;
done_testing;
