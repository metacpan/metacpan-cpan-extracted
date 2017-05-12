use strict;
use Test::More;
use lib '../lib';
use Box::Calc;
use Ouch;
use 5.010;

my $user_id  = $ENV{USPS_USERID};
my $password = $ENV{USPS_PASSWORD};

if (!$user_id || !$password) {
    plan skip_all => 'Missing USPS_USERID or USPS_PASSWORD';
}

use_ok 'USPS::RateRequest';

my $calc = Box::Calc->new();
$calc->add_box_type({
    x => 12,
    y => 12,
    z => 5.75,
    weight => 10,
    name => 'A',
});
$calc->add_item(2,
    x => 8,
    y => 8,
    z => 5.75,
    name => 'tiny pumpkin',
    weight => 10,
);
$calc->pack_items;

my $countries = q|Albania
Algeria
Andorra
Angola
Argentina
Armenia
Aruba
Australia
Austria
Azerbaijan
Azores
Bahamas
Bahrain
Bangladesh
Barbados
Belarus
Belgium
Belize
Benin
Bermuda
Bhutan
Bolivia
Bosnia-Herzegovina
Botswana
Brazil
Brunei Darussalam
Bulgaria
Burkina Faso
Burundi
Cambodia
Cameroon
Canada
Cape Verde
Cayman Islands
Central African Republic
Chad
Chile
China
Colombia
Congo, Democratic Republic of the
Congo, Republic of the
Corsica
Costa Rica
Ivory Coast
Croatia
Cyprus
Czech Republic
Denmark
Djibouti
Dominican Republic
Ecuador
Egypt
El Salvador
Equatorial Guinea
Eritrea
Estonia
Ethiopia
Faroe Islands
Fiji
Finland
France
French Guiana
French Polynesia
Gabon
Georgia
Germany
Ghana
United Kingdom
Greece
Grenada
Guadeloupe
Guatemala
Guinea
Guinea-Bissau
Guyana
Haiti
Honduras
Hong Kong
Hungary
Iceland
India
Indonesia
Iran
Iraq
Ireland
Israel
Italy
Jamaica
Japan
Jordan
Kazakhstan
Kenya
South Korea
Kuwait
Kyrgyzstan
Laos
Latvia
Lesotho
Liberia
Liechtenstein
Lithuania
Luxembourg
Macao
Macedonia
Madagascar
Madeira Islands
Malawi
Malaysia
Maldives
Mali
Malta
Martinique
Mauritania
Mauritius
Mexico
Moldova
Mongolia
Morocco
Mozambique
Namibia
Nauru
Nepal
Netherlands
Netherlands Antilles
New Caledonia
New Zealand
Nicaragua
Niger
Nigeria
Norway
Oman
Pakistan
Panama
Papua New Guinea
Paraguay
Peru
Philippines
Poland
Portugal
Qatar
Romania
Russia
Rwanda
Nevis (Saint Christopher and Nevis)
Saint Lucia
Saint Vincent and the Grenadines
Saudi Arabia
Senegal
Serbia Montenegro
Seychelles
Sierra Leone
Singapore
Slovak Republic
Slovenia
Solomon Islands
Somalia
South Africa
Spain
Sri Lanka
Sudan
Swaziland
Sweden
Switzerland
Syrian Arab Republic (Syria)
Taiwan
Tajikistan
Tanzania
Thailand
Togo
Tobago (Trinidad and Tobago)
Tunisia
Turkey
Turkmenistan
Uganda
Ukraine
United Arab Emirates
Uruguay
Vanuatu
Venezuela
Vietnam
Western Samoa
Yemen|;

my @countries = split "\n", $countries;

foreach my $country (@countries) {

    next unless $country;

    my $rate = USPS::RateRequest->new(
        user_id     => $user_id,
        password    => $password,
        from        => 53716,
        to          => $country,
    );

    my $rates = eval { $rate->request_rates($calc->boxes)->recv; };
    if (hug) {
        fail "$country failed";
    }
    else {
        pass "$country passed";
    }
}
done_testing();
