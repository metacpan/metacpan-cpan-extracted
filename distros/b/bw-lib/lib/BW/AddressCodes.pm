# AddressCodes.pm
# by Bill Weinman -- Address codes for Countries and US States
# Copyright (c) 1995-2010 The BearHeart Group, LLC
#
# See POD for History
#
package BW::AddressCodes;
use strict;
use warnings;

use BW::Constants;
use base qw( BW::Base );

use Exporter;    # can't use qw( import ) with old version of perl
our @EXPORT = qw ( us_state_codes country_codes );

our $VERSION = "1.0";

my $codes = {
    us_state_codes => [
        { text => "-- Select State --",       value => "" },
        { text => "Alabama",                  value => "AL" },
        { text => "Alaska",                   value => "AK" },
        { text => "American Samoa",           value => "AS" },
        { text => "Arizona",                  value => "AZ" },
        { text => "Arkansas",                 value => "AR" },
        { text => "California",               value => "CA" },
        { text => "Colorado",                 value => "CO" },
        { text => "Connecticut",              value => "CT" },
        { text => "Delaware",                 value => "DE" },
        { text => "District of Columbia",     value => "DC" },
        { text => "Florida",                  value => "FL" },
        { text => "Georgia",                  value => "GA" },
        { text => "Guam",                     value => "GU" },
        { text => "Hawaii",                   value => "HI" },
        { text => "Idaho",                    value => "ID" },
        { text => "Illinois",                 value => "IL" },
        { text => "Indiana",                  value => "IN" },
        { text => "Iowa",                     value => "IA" },
        { text => "Kansas",                   value => "KS" },
        { text => "Kentucky",                 value => "KY" },
        { text => "Louisiana",                value => "LA" },
        { text => "Maine",                    value => "ME" },
        { text => "Marshall Islands",         value => "MH" },
        { text => "Maryland",                 value => "MD" },
        { text => "Massachusetts",            value => "MA" },
        { text => "Michigan",                 value => "MI" },
        { text => "Minnesota",                value => "MN" },
        { text => "Mississippi",              value => "MS" },
        { text => "Missouri",                 value => "MO" },
        { text => "Montana",                  value => "MT" },
        { text => "Nebraska",                 value => "NE" },
        { text => "Nevada",                   value => "NV" },
        { text => "New Hampshire",            value => "NH" },
        { text => "New Jersey",               value => "NJ" },
        { text => "New Mexico",               value => "NM" },
        { text => "New York",                 value => "NY" },
        { text => "North Carolina",           value => "NC" },
        { text => "North Dakota",             value => "ND" },
        { text => "Northern Mariana Islands", value => "MP" },
        { text => "Ohio",                     value => "OH" },
        { text => "Oklahoma",                 value => "OK" },
        { text => "Oregon",                   value => "OR" },
        { text => "Palau",                    value => "PW" },
        { text => "Pennsylvania",             value => "PA" },
        { text => "Puerto Rico",              value => "PR" },
        { text => "Rhode Island",             value => "RI" },
        { text => "South Carolina",           value => "SC" },
        { text => "South Dakota",             value => "SD" },
        { text => "Tennessee",                value => "TN" },
        { text => "Texas",                    value => "TX" },
        { text => "Utah",                     value => "UT" },
        { text => "Vermont",                  value => "VT" },
        { text => "Virgin Islands",           value => "VI" },
        { text => "Virginia",                 value => "VA" },
        { text => "Washington",               value => "WA" },
        { text => "West Virginia",            value => "WV" },
        { text => "Wisconsin",                value => "WI" },
        { text => "Wyoming",                  value => "WY" }
    ],

    country_codes => [
        { text => "United States",                                value => "US", selected => TRUE },
        { text => "Canada",                                       value => "CA" },
        { text => "----------",                                   value => "" },
        { text => "Afghanistan",                                  value => "AF" },
        { text => "Albania",                                      value => "AL" },
        { text => "Algeria",                                      value => "DZ" },
        { text => "American Samoa",                               value => "AS" },
        { text => "Andorra",                                      value => "AD" },
        { text => "Angola",                                       value => "AO" },
        { text => "Anguilla",                                     value => "AI" },
        { text => "Antarctica",                                   value => "AQ" },
        { text => "Antigua and Barbuda",                          value => "AG" },
        { text => "Argentina",                                    value => "AR" },
        { text => "Armenia",                                      value => "AM" },
        { text => "Aruba",                                        value => "AW" },
        { text => "Australia",                                    value => "AU" },
        { text => "Austria",                                      value => "AT" },
        { text => "Azerbaijan",                                   value => "AZ" },
        { text => "Bahamas",                                      value => "BS" },
        { text => "Bahrain",                                      value => "BH" },
        { text => "Bangladesh",                                   value => "BD" },
        { text => "Barbados",                                     value => "BB" },
        { text => "Belarus",                                      value => "BY" },
        { text => "Belgium",                                      value => "BE" },
        { text => "Belize",                                       value => "BZ" },
        { text => "Benin",                                        value => "BJ" },
        { text => "Bermuda",                                      value => "BM" },
        { text => "Bhutan",                                       value => "BT" },
        { text => "Bolivia",                                      value => "BO" },
        { text => "Bosnia and Herzegovina",                       value => "BA" },
        { text => "Botswana",                                     value => "BW" },
        { text => "Bouvet Island",                                value => "BV" },
        { text => "Brazil",                                       value => "BR" },
        { text => "British Indian Ocean Territory",               value => "IO" },
        { text => "Brunei Darussalam",                            value => "BN" },
        { text => "Bulgaria",                                     value => "BG" },
        { text => "Burkina Faso",                                 value => "BF" },
        { text => "Burundi",                                      value => "BI" },
        { text => "Cambodia",                                     value => "KH" },
        { text => "Cameroon",                                     value => "CM" },
        { text => "Canada",                                       value => "CA" },
        { text => "Cape Verde",                                   value => "CV" },
        { text => "Cayman Islands",                               value => "KY" },
        { text => "Central African Republic",                     value => "CF" },
        { text => "Chad",                                         value => "TD" },
        { text => "Chile",                                        value => "CL" },
        { text => "China",                                        value => "CN" },
        { text => "Christmas Island",                             value => "CX" },
        { text => "Cocos (Keeling) Islands",                      value => "CC" },
        { text => "Colombia",                                     value => "CO" },
        { text => "Comoros",                                      value => "KM" },
        { text => "Congo, the Democratic Republic of the",        value => "CD" },
        { text => "Congo",                                        value => "CG" },
        { text => "Cook Islands",                                 value => "CK" },
        { text => "Costa Rica",                                   value => "CR" },
        { text => "Cote d'Ivoire",                                value => "CI" },
        { text => "Croatia",                                      value => "HR" },
        { text => "Cuba",                                         value => "CU" },
        { text => "Cyprus",                                       value => "CY" },
        { text => "Czech Republic",                               value => "CZ" },
        { text => "Denmark",                                      value => "DK" },
        { text => "Djibouti",                                     value => "DJ" },
        { text => "Dominica",                                     value => "DM" },
        { text => "Dominican Republic",                           value => "DO" },
        { text => "Ecuador",                                      value => "EC" },
        { text => "Egypt",                                        value => "EG" },
        { text => "El Salvador",                                  value => "SV" },
        { text => "Equatorial Guinea",                            value => "GQ" },
        { text => "Eritrea",                                      value => "ER" },
        { text => "Estonia",                                      value => "EE" },
        { text => "Ethiopia",                                     value => "ET" },
        { text => "Falkland Islands (Malvinas)",                  value => "FK" },
        { text => "Faroe Islands",                                value => "FO" },
        { text => "Fiji",                                         value => "FJ" },
        { text => "Finland",                                      value => "FI" },
        { text => "France",                                       value => "FR" },
        { text => "French Guiana",                                value => "GF" },
        { text => "French Polynesia",                             value => "PF" },
        { text => "French Southern Territories",                  value => "TF" },
        { text => "Gabon",                                        value => "GA" },
        { text => "Gambia",                                       value => "GM" },
        { text => "Georgia",                                      value => "GE" },
        { text => "Germany",                                      value => "DE" },
        { text => "Ghana",                                        value => "GH" },
        { text => "Gibraltar",                                    value => "GI" },
        { text => "Greece",                                       value => "GR" },
        { text => "Greenland",                                    value => "GL" },
        { text => "Grenada",                                      value => "GD" },
        { text => "Guadeloupe",                                   value => "GP" },
        { text => "Guam",                                         value => "GU" },
        { text => "Guatemala",                                    value => "GT" },
        { text => "Guernsey",                                     value => "GG" },
        { text => "Guinea-Bissau",                                value => "GW" },
        { text => "Guinea",                                       value => "GN" },
        { text => "Guyana",                                       value => "GY" },
        { text => "Haiti",                                        value => "HT" },
        { text => "Heard Island and McDonald Islands",            value => "HM" },
        { text => "Holy See (Vatican City State)",                value => "VA" },
        { text => "Honduras",                                     value => "HN" },
        { text => "Hong Kong",                                    value => "HK" },
        { text => "Hungary",                                      value => "HU" },
        { text => "Iceland",                                      value => "IS" },
        { text => "India",                                        value => "IN" },
        { text => "Indonesia",                                    value => "ID" },
        { text => "Iran, Islamic Republic of",                    value => "IR" },
        { text => "Iraq",                                         value => "IQ" },
        { text => "Ireland",                                      value => "IE" },
        { text => "Isle of Man",                                  value => "IM" },
        { text => "Israel",                                       value => "IL" },
        { text => "Italy",                                        value => "IT" },
        { text => "Jamaica",                                      value => "JM" },
        { text => "Japan",                                        value => "JP" },
        { text => "Jersey",                                       value => "JE" },
        { text => "Jordan",                                       value => "JO" },
        { text => "Kazakhstan",                                   value => "KZ" },
        { text => "Kenya",                                        value => "KE" },
        { text => "Kiribati",                                     value => "KI" },
        { text => "Korea, Democratic People's Republic of",       value => "KP" },
        { text => "Korea, Republic of",                           value => "KR" },
        { text => "Kuwait",                                       value => "KW" },
        { text => "Kyrgyzstan",                                   value => "KG" },
        { text => "Lao People's Democratic Republic",             value => "LA" },
        { text => "Latvia",                                       value => "LV" },
        { text => "Lebanon",                                      value => "LB" },
        { text => "Lesotho",                                      value => "LS" },
        { text => "Liberia",                                      value => "LR" },
        { text => "Libyan Arab Jamahiriya",                       value => "LY" },
        { text => "Liechtenstein",                                value => "LI" },
        { text => "Lithuania",                                    value => "LT" },
        { text => "Luxembourg",                                   value => "LU" },
        { text => "Macao",                                        value => "MO" },
        { text => "Macedonia, the former Yugoslav Republic of",   value => "MK" },
        { text => "Madagascar",                                   value => "MG" },
        { text => "Malawi",                                       value => "MW" },
        { text => "Malaysia",                                     value => "MY" },
        { text => "Maldives",                                     value => "MV" },
        { text => "Mali",                                         value => "ML" },
        { text => "Malta",                                        value => "MT" },
        { text => "Marshall Islands",                             value => "MH" },
        { text => "Martinique",                                   value => "MQ" },
        { text => "Mauritania",                                   value => "MR" },
        { text => "Mauritius",                                    value => "MU" },
        { text => "Mayotte",                                      value => "YT" },
        { text => "Mexico",                                       value => "MX" },
        { text => "Micronesia, Federated States of",              value => "FM" },
        { text => "Moldova, Republic of",                         value => "MD" },
        { text => "Monaco",                                       value => "MC" },
        { text => "Mongolia",                                     value => "MN" },
        { text => "Montenegro",                                   value => "ME" },
        { text => "Montserrat",                                   value => "MS" },
        { text => "Morocco",                                      value => "MA" },
        { text => "Mozambique",                                   value => "MZ" },
        { text => "Myanmar",                                      value => "MM" },
        { text => "Namibia",                                      value => "NA" },
        { text => "Nauru",                                        value => "NR" },
        { text => "Nepal",                                        value => "NP" },
        { text => "Netherlands Antilles",                         value => "AN" },
        { text => "Netherlands",                                  value => "NL" },
        { text => "New Caledonia",                                value => "NC" },
        { text => "New Zealand",                                  value => "NZ" },
        { text => "Nicaragua",                                    value => "NI" },
        { text => "Niger",                                        value => "NE" },
        { text => "Nigeria",                                      value => "NG" },
        { text => "Niue",                                         value => "NU" },
        { text => "Norfolk Island",                               value => "NF" },
        { text => "Northern Mariana Islands",                     value => "MP" },
        { text => "Norway",                                       value => "NO" },
        { text => "Oman",                                         value => "OM" },
        { text => "Pakistan",                                     value => "PK" },
        { text => "Palau",                                        value => "PW" },
        { text => "Palestinian Territory, Occupied",              value => "PS" },
        { text => "Panama",                                       value => "PA" },
        { text => "Papua New Guinea",                             value => "PG" },
        { text => "Paraguay",                                     value => "PY" },
        { text => "Peru",                                         value => "PE" },
        { text => "Philippines",                                  value => "PH" },
        { text => "Pitcairn",                                     value => "PN" },
        { text => "Poland",                                       value => "PL" },
        { text => "Portugal",                                     value => "PT" },
        { text => "Puerto Rico",                                  value => "PR" },
        { text => "Qatar",                                        value => "QA" },
        { text => "Reunion",                                      value => "RE" },
        { text => "Romania",                                      value => "RO" },
        { text => "Russian Federation",                           value => "RU" },
        { text => "Rwanda",                                       value => "RW" },
        { text => "Saint Barthelemy",                             value => "BL" },
        { text => "Saint Helena",                                 value => "SH" },
        { text => "Saint Kitts and Nevis",                        value => "KN" },
        { text => "Saint Lucia",                                  value => "LC" },
        { text => "Saint Martin (French part)",                   value => "MF" },
        { text => "Saint Pierre and Miquelon",                    value => "PM" },
        { text => "Saint Vincent and the Grenadines",             value => "VC" },
        { text => "Samoa",                                        value => "WS" },
        { text => "San Marino",                                   value => "SM" },
        { text => "Sao Tome and Principe",                        value => "ST" },
        { text => "Saudi Arabia",                                 value => "SA" },
        { text => "Senegal",                                      value => "SN" },
        { text => "Serbia",                                       value => "RS" },
        { text => "Seychelles",                                   value => "SC" },
        { text => "Sierra Leone",                                 value => "SL" },
        { text => "Singapore",                                    value => "SG" },
        { text => "Slovakia",                                     value => "SK" },
        { text => "Slovenia",                                     value => "SI" },
        { text => "Solomon Islands",                              value => "SB" },
        { text => "Somalia",                                      value => "SO" },
        { text => "South Africa",                                 value => "ZA" },
        { text => "South Georgia and the South Sandwich Islands", value => "GS" },
        { text => "Spain",                                        value => "ES" },
        { text => "Sri Lanka",                                    value => "LK" },
        { text => "Sudan",                                        value => "SD" },
        { text => "Suriname",                                     value => "SR" },
        { text => "Svalbard and Jan Mayen",                       value => "SJ" },
        { text => "Swaziland",                                    value => "SZ" },
        { text => "Sweden",                                       value => "SE" },
        { text => "Switzerland",                                  value => "CH" },
        { text => "Syrian Arab Republic",                         value => "SY" },
        { text => "Taiwan, Province of China",                    value => "TW" },
        { text => "Tajikistan",                                   value => "TJ" },
        { text => "Tanzania, United Republic of",                 value => "TZ" },
        { text => "Thailand",                                     value => "TH" },
        { text => "Timor-Leste",                                  value => "TL" },
        { text => "Togo",                                         value => "TG" },
        { text => "Tokelau",                                      value => "TK" },
        { text => "Tonga",                                        value => "TO" },
        { text => "Trinidad and Tobago",                          value => "TT" },
        { text => "Tunisia",                                      value => "TN" },
        { text => "Turkey",                                       value => "TR" },
        { text => "Turkmenistan",                                 value => "TM" },
        { text => "Turks and Caicos Islands",                     value => "TC" },
        { text => "Tuvalu",                                       value => "TV" },
        { text => "Uganda",                                       value => "UG" },
        { text => "Ukraine",                                      value => "UA" },
        { text => "United Arab Emirates",                         value => "AE" },
        { text => "United Kingdom",                               value => "GB" },
        { text => "United States Minor Outlying Islands",         value => "UM" },
        { text => "United States",                                value => "US" },
        { text => "Uruguay",                                      value => "UY" },
        { text => "Uzbekistan",                                   value => "UZ" },
        { text => "Vanuatu",                                      value => "VU" },
        { text => "Venezuela",                                    value => "VE" },
        { text => "Viet Nam",                                     value => "VN" },
        { text => "Virgin Islands, British",                      value => "VG" },
        { text => "Virgin Islands, U.S.",                         value => "VI" },
        { text => "Wallis and Futuna",                            value => "WF" },
        { text => "Western Sahara",                               value => "EH" },
        { text => "Yemen",                                        value => "YE" },
        { text => "Zambia",                                       value => "ZM" },
        { text => "Zimbabwe",                                     value => "ZW" },
    ],

    stub => VOID
};

sub us_state_codes
{
    return $codes->{us_state_codes};
}

sub country_codes
{
    return $codes->{country_codes};
}

1;

=head1 NAME

BW::AddressCodes - New module description

=head1 SYNOPSIS

  use BW::AddressCodes;
  my $o = BW::AddressCodes->new;

=head1 METHODS

=over 4

=item B<new>( )

Constructs a new BW::AddressCodes object. 

Returns a blessed BW::AddressCodes object reference.
Returns undef (VOID) if the object cannot be created. 

=item B<us_state_codes>( )

Returns the US state codes as an array of hashrefs. 

=item B<country_codes>( )

Returns the country codes as an array of hashrefs. 

=item B<error>

Returns and clears the object error message.

=back

=head1 AUTHOR

Written by Bill Weinman E<lt>http://bw.org/E<gt>.

=head1 COPYRIGHT

Copyright (c) 1995-2010 The BearHeart Group, LLC

=head1 HISTORY

  2010-02-14 bw 1.0 -- updated for CPAN distribution
  2008-05-28 bw     -- updated documentation
  2008-04-14 bw     -- initial version.

=cut

