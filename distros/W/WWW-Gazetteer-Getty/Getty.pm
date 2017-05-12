package WWW::Gazetteer::Getty;
use strict;
use warnings;
use Carp qw(croak);
use HTTP::Cookies;
use LWP::UserAgent;
use URI::QueryParam;

use vars qw($VERSION);
$VERSION = '0.11';

my $countries = {
    af => 'Afghanistan',
    al => 'Albania',
    dz => 'Algeria',
    as => 'American Samoa',
    ad => 'Andorra',
    ao => 'Angola',
    ai => 'Anguilla',
    aq => 'Antarctica',
    ag => 'Antigua and Barbuda',
    ar => 'Argentina',
    am => 'Armenia',
    aw => 'Aruba',
    au => 'Australia',
    at => 'Austria',
    az => 'Azerbaijan',
    bs => 'Bahamas',
    bh => 'Bahrain',
    bd => 'Bangladesh',
    bb => 'Barbados',
    by => 'Belarus',
    be => 'Belgium',
    bz => 'Belize',
    bj => 'Benin',
    bm => 'Bermuda',
    bt => 'Bhutan',
    bo => 'Bolivia',
    ba => 'Bosnia and Herzegovina',
    bw => 'Botswana',
    bv => 'Bouvet Island',
    br => 'Brazil',
    io => 'British Indian Ocean Territory',
    bn => 'Brunei Darussalam',
    bg => 'Bulgaria',
    bf => 'Burkina Faso',
    bi => 'Burundi',
    kh => 'Cambodia',
    cm => 'Cameroon',
    ca => 'Canada',
    cv => 'Cape Verde',
    ky => 'Cayman Islands',
    cf => 'Central African Republic',
    td => 'Chad',
    cl => 'Chile',
    cn => 'China',
    cx => 'Christmas Island',
    cc => 'Cocos (Keeling) Islands',
    co => 'Colombia',
    km => 'Comoros',
    cg => 'Congo',
    ck => 'Cook Islands',
    cr => 'Costa Rica',
    ci => "Cote D'Ivoire",
    hr => 'Croatia',
    cu => 'Cuba',
    cy => 'Cyprus',
    cz => 'Czech Republic',
    dk => 'Denmark',
    dj => 'Djibouti',
    dm => 'Dominica',
    do => 'Dominican Republic',
    tl => 'East Timor',
    ec => 'Ecuador',
    eg => 'Egypt',
    sv => 'El Salvador',
    gq => 'Equatorial Guinea',
    er => 'Eritrea',
    ee => 'Estonia',
    et => 'Ethiopia',
    fk => 'Falkland Islands (Malvinas)',
    fo => 'Faroe Islands',
    fj => 'Fiji',
    fi => 'Finland',
    fr => 'France',
    fx => 'France, Metropolitan',
    gf => 'French Guiana',
    pf => 'French Polynesia',
    tf => 'French Southern Territories',
    ga => 'Gabon',
    gm => 'Gambia',
    ge => 'Georgia',
    de => 'Germany',
    gh => 'Ghana',
    gi => 'Gibraltar',
    gr => 'Greece',
    gl => 'Greenland',
    gd => 'Grenada',
    gp => 'Guadeloupe',
    gu => 'Guam',
    gt => 'Guatemala',
    gn => 'Guinea',
    gw => 'Guinea-Bissau',
    gy => 'Guyana',
    ht => 'Haiti',
    hm => 'Heard Island and McDonald Islands',
    va => 'Holy See (Vatican City State)',
    hn => 'Honduras',
    hk => 'Hong Kong',
    hu => 'Hungary',
    is => 'Iceland',
    in => 'India',
    id => 'Indonesia',
    ir => 'Iran, Islamic Republic of',
    iq => 'Iraq',
    ie => 'Ireland',
    il => 'Israel',
    it => 'Italy',
    jm => 'Jamaica',
    jp => 'Japan',
    jo => 'Jordan',
    kz => 'Kazakhstan',
    ke => 'Kenya',
    ki => 'Kiribati',
    kp => "Korea, Democratic People's Republic of",
    kr => 'Korea, Republic of',
    kw => 'Kuwait',
    kg => 'Kyrgyzstan',
    la => "Lao People's Democratic Republic",
    lv => 'Latvia',
    lb => 'Lebanon',
    ls => 'Lesotho',
    lr => 'Liberia',
    ly => 'Libyan Arab Jamahiriya',
    li => 'Liechtenstein',
    lt => 'Lithuania',
    lu => 'Luxembourg',
    mo => 'Macao',
    mk => 'Macedonia, the Former Yugoslav Republic of',
    mg => 'Madagascar',
    mw => 'Malawi',
    my => 'Malaysia',
    mv => 'Maldives',
    ml => 'Mali',
    mt => 'Malta',
    mh => 'Marshall Islands',
    mq => 'Martinique',
    mr => 'Mauritania',
    mu => 'Mauritius',
    yt => 'Mayotte',
    mx => 'Mexico',
    fm => 'Micronesia, Federated States of',
    md => 'Moldova, Republic of',
    mc => 'Monaco',
    mn => 'Mongolia',
    ms => 'Montserrat',
    ma => 'Morocco',
    mz => 'Mozambique',
    mm => 'Myanmar',
    na => 'Namibia',
    nr => 'Nauru',
    np => 'Nepal',
    nl => 'Netherlands',
    an => 'Netherlands Antilles',
    nc => 'New Caledonia',
    nz => 'New Zealand',
    ni => 'Nicaragua',
    ne => 'Niger',
    ng => 'Nigeria',
    nu => 'Niue',
    nf => 'Norfolk Island',
    mp => 'Northern Mariana Islands',
    no => 'Norway',
    om => 'Oman',
    pk => 'Pakistan',
    pw => 'Palau',
    ps => 'Palestinian Territory, Occupied',
    pa => 'Panama',
    pg => 'Papua New Guinea',
    py => 'Paraguay',
    pe => 'Peru',
    ph => 'Philippines',
    pn => 'Pitcairn',
    pl => 'Poland',
    pt => 'Portugal',
    pr => 'Puerto Rico',
    qa => 'Qatar',
    re => 'Reunion',
    ro => 'Romania',
    ru => 'Russian Federation',
    rw => 'Rwanda',
    sh => 'Saint Helena',
    kn => 'Saint Kitts and Nevis',
    lc => 'Saint Lucia',
    pm => 'Saint Pierre and Miquelon',
    vc => 'Saint Vincent and the Grenadines',
    ws => 'Samoa',
    sm => 'San Marino',
    st => 'Sao Tome and Principe',
    sa => 'Saudi Arabia',
    sn => 'Senegal',
    sc => 'Seychelles',
    sl => 'Sierra Leone',
    sg => 'Singapore',
    sk => 'Slovakia',
    si => 'Slovenia',
    sb => 'Solomon Islands',
    so => 'Somalia',
    za => 'South Africa',
    gs => 'South Georgia and the South Sandwich Islands',
    es => 'Spain',
    lk => 'Sri Lanka',
    sd => 'Sudan',
    sr => 'Suriname',
    sj => 'Svalbard and Jan Mayen',
    sz => 'Swaziland',
    se => 'Sweden',
    ch => 'Switzerland',
    sy => 'Syrian Arab Republic',
    tw => 'Taiwan, Province of China',
    tj => 'Tajikistan',
    tz => 'Tanzania, United Republic of',
    th => 'Thailand',
    tg => 'Togo',
    tk => 'Tokelau',
    to => 'Tonga',
    tt => 'Trinidad and Tobago',
    tn => 'Tunisia',
    tr => 'Turkey',
    tm => 'Turkmenistan',
    tc => 'Turks and Caicos Islands',
    tv => 'Tuvalu',
    ug => 'Uganda',
    ua => 'Ukraine',
    ae => 'United Arab Emirates',
    gb => 'United Kingdom',
    uk => 'United Kingdom',
    us => 'United States',
    um => 'United States Minor Outlying Islands',
    uy => 'Uruguay',
    uz => 'Uzbekistan',
    vu => 'Vanuatu',
    ve => 'Venezuela',
    vn => 'Vietnam',
    vg => 'Virgin Islands, British',
    vi => 'Virgin Islands, U.S.',
    wf => 'Wallis and Futuna',
    eh => 'Western Sahara',
    ye => 'Yemen',
    yu => 'Yugoslavia',
    zr => 'Zaire',
    zm => 'Zambia',
    zw => 'Zimbabwe',
};

sub new {
    my ($class) = @_;

    my $self = {};
    my $ua   = LWP::UserAgent->new(
        env_proxy  => 1,
        keep_alive => 1,
        timeout    => 30,
    );
    $ua->agent( "WWW::Gazetteer::Getty/$VERSION " . $ua->agent );

    $self->{ua} = $ua;

    bless $self, $class;
    return $self;
}

sub find {
    my ( $self, $city, $country ) = @_;

    if ( $countries->{ lc $country } ) {
        $country = $countries->{ lc $country };
    }

    my $ua = $self->{ua};

# http://www.getty.edu/vow/TGNServlet?english=Y&find=London&place=&page=1&nation=United+Kingdom
    my $search_url = URI->new("http://www.getty.edu/vow/TGNServlet");
    $search_url->query_param( 'english' => 'Y' );
    $search_url->query_param( 'find'    => $city );
    $search_url->query_param( 'place'   => undef );
    $search_url->query_param( 'page'    => 1 );
    $search_url->query_param( 'nation'  => $country );

    my $request = HTTP::Request->new( 'GET', $search_url );
    my $response = $ua->request($request);

    if ( not $response->is_success ) {
        croak("WWW::Gazetteer::Getty: City $city in $country not found");
        return;
    }

    my @cities;
    my $content = $response->content;

    my @bits = split /checkbox/, $content;

    my @ids;
    foreach my $bit (@bits) {
        my ($id) = $bit =~ m{subjectid=(\d+)};
        next unless $id;
        push @ids, $id;
    }

    foreach my $id (@ids) {

# http://www.getty.edu/vow/TGNFullDisplay?find=London&place=&nation=United+Kingdom&prev_page=1&english=Y&subjectid=7018906
        my $detail_url = URI->new("http://www.getty.edu/vow/TGNFullDisplay");
        $detail_url->query_param( 'english'   => 'Y' );
        $detail_url->query_param( 'find'      => $city );
        $detail_url->query_param( 'place'     => undef );
        $detail_url->query_param( 'page'      => 1 );
        $detail_url->query_param( 'nation'    => $country );
        $detail_url->query_param( 'subjectid' => $id );

        $request = HTTP::Request->new( 'GET', $detail_url );
        $response = $ua->request($request);

        if ( not $response->is_success ) {
            croak("WWW::Gazetteer::Getty: City $city in $country not found");
            return;
        }

        $content = $response->content;

# <TD COLSPAN=2 VALIGN=TOP NOWRAP><SPAN CLASS=page>&nbsp;&nbsp;Lat:  51.5000&nbsp;&nbsp;<I>decimal degrees</I></SPAN></TD></TR>
# <TD COLSPAN=2 VALIGN=TOP NOWRAP><SPAN CLASS=page>&nbsp;&nbsp;Long:   -0.0833&nbsp;&nbsp;<I>decimal degrees</I></SPAN></TD></TR>
        my ($latitude)
            = $content
            =~ m{Lat:\s+([0-9.-]+)&nbsp;&nbsp;<I>decimal degrees</I>};
        my ($longitude)
            = $content
            =~ m{Long:\s+([0-9.-]+)&nbsp;&nbsp;<I>decimal degrees</I>};

        push @cities,
            {
            city      => $city,
            country   => $country,
            latitude  => $latitude,
            longitude => $longitude,
            };
    }
    return wantarray ? @cities : \@cities;
}

__END__

=head1 NAME

WWW::Gazetteer::Getty - Find location of world towns and cities

=head1 SYNOPSYS

  use WWW::Gazetteer;
  my $g = WWW::Gazetteer::Getty->new('getty');
  my @londons = $g->find('London', 'UK');
  my $london = $londons[0];
  print $london->{longitude}, ", ", $london->{latitude}, "\n";
  my $nice = $g->find("Nice", "France")->[0];
  print $nice->{city}, ", ", $nice->{elevation}, "\n";

=head1 DESCRIPTION

A gazetteer is a geographical dictionary (as at the back of an
atlas). The C<WWW::Gazetteer::Getty> module uses the information at
http://www.getty.edu/research/conducting_research/vocabularies/tgn/
to return geographical location (longitude, latitude) for towns and 
cities in countries in the world.

This module is a subclass of C<WWW::Gazetteer>, so you must use that
to create a C<WWW::Gazetteer::Getty> object. Once you have imported
the module and created a gazetteer object, calling find($country =>
$town) will return a list of hashrefs with longitude and latitude
information.

  my @londons = $g->find('London', 'UK');
  my $london = $londons[0];
  print $london->{longitude}, ", ", $london->{latitude}, "\n";
  # prints -0.1167, 51.5000

The hashref for London actually looks like this:

  $london = {
    longitude => "-0.167",
    latitude  => "51.500",
    city      => 'London',
    country   => 'United Kingdom',
  };

The city and country values are the same as the ones you used. The
longitude and latitude are in degrees, ranging from -180 to 180 where
(0, 0) is on the Prime Meridian and the equator.

=head1 METHODS

=head2 new()

This returns a new WWW::Gazetteer::Getty object. It currently has no
arguments:

  use WWW::Gazetteer;
  my $g = WWW::Gazetteer->new('getty');

=head2 find()

The find method looks up geographical information and returns it to
you. It takes in a country and a city, with the recommended syntax
being a city name and ISO 3166 code.

Note that there may be more than one town or city with that name in
the country. You will get a list of hashrefs for each town/city.

  my @londons = $g->find("London", "UK");
  my @londons = $g->find("London", "United Kingdom");

The following countries are valid (as are their ISO 3166 codes):
Afghanistan, Albania, Algeria, American Samoa, Andorra, Angola,
Anguilla, Antarctica, Antigua and Barbuda, Argentina, Armenia, Aruba,
Australia, Austria, Azerbaijan, Bahamas, Bahrain, Bangladesh,
Barbados, Belarus, Belgium, Belize, Benin, Bermuda, Bhutan, Bolivia,
Bosnia and Herzegovina, Botswana, Bouvet Island, Brazil, British
Indian Ocean Territory, Brunei Darussalam, Bulgaria, Burkina Faso,
Burundi, Cambodia, Cameroon, Canada, Cape Verde, Cayman Islands,
Central African Republic, Chad, Chile, China, Christmas Island, Cocos
(Keeling) Islands, Colombia, Comoros, Congo, Cook Islands, Costa Rica,
Cote D'Ivoire, Croatia, Cuba, Cyprus, Czech Republic, Denmark,
Djibouti, Dominica, Dominican Republic, East Timor, Ecuador, Egypt, El
Salvador, Equatorial Guinea, Eritrea, Estonia, Ethiopia, Falkland
Islands (Malvinas), Faroe Islands, Fiji, Finland, France, France,
Metropolitan, French Guiana, French Polynesia, French Southern
Territories, Gabon, Gambia, Georgia, Germany, Ghana, Gibraltar,
Greece, Greenland, Grenada, Guadeloupe, Guam, Guatemala, Guinea,
Guinea-Bissau, Guyana, Haiti, Heard Island and McDonald Islands, Holy
See (Vatican City State), Honduras, Hong Kong, Hungary, Iceland,
India, Indonesia, Iran, Islamic Republic of, Iraq, Ireland, Israel,
Italy, Jamaica, Japan, Jordan, Kazakhstan, Kenya, Kiribati, Korea,
Democratic People's Republic of, Korea, Republic of, Kuwait,
Kyrgyzstan, Lao People's Democratic Republic, Latvia, Lebanon,
Lesotho, Liberia, Libyan Arab Jamahiriya, Liechtenstein, Lithuania,
Luxembourg, Macao, Macedonia, the Former Yugoslav Republic of,
Madagascar, Malawi, Malaysia, Maldives, Mali, Malta, Marshall Islands,
Martinique, Mauritania, Mauritius, Mayotte, Mexico, Micronesia,
Federated States of, Moldova, Republic of, Monaco, Mongolia,
Montserrat, Morocco, Mozambique, Myanmar, Namibia, Nauru, Nepal,
Netherlands, Netherlands Antilles, New Caledonia, New Zealand,
Nicaragua, Niger, Nigeria, Niue, Norfolk Island, Northern Mariana
Islands, Norway, Oman, Pakistan, Palau, Palestinian Territory,
Occupied, Panama, Papua New Guinea, Paraguay, Peru, Philippines,
Pitcairn, Poland, Portugal, Puerto Rico, Qatar, Reunion, Romania,
Russian Federation, Rwanda, Saint Helena, Saint Kitts and Nevis, Saint
Lucia, Saint Pierre and Miquelon, Saint Vincent and the Grenadines,
Samoa, San Marino, Sao Tome and Principe, Saudi Arabia, Senegal,
Seychelles, Sierra Leone, Singapore, Slovakia, Slovenia, Solomon
Islands, Somalia, South Africa, South Georgia and the South Sandwich
Islands, Spain, Sri Lanka, Sudan, Suriname, Svalbard and Jan Mayen,
Swaziland, Sweden, Switzerland, Syrian Arab Republic, Taiwan, Province
of China, Tajikistan, Tanzania, United Republic of, Thailand, Togo,
Tokelau, Tonga, Trinidad and Tobago, Tunisia, Turkey, Turkmenistan,
Turks and Caicos Islands, Tuvalu, Uganda, Ukraine, United Arab
Emirates, United Kingdom, United Kingdom, United States, United States
Minor Outlying Islands, Uruguay, Uzbekistan, Vanuatu, Venezuela,
Vietnam, Virgin Islands, British, Virgin Islands, U.S., Wallis and
Futuna, Western Sahara, Yemen, Yugoslavia, Zaire, Zambia, Zimbabwe.

Note that there may be bugs in the Getty database. Do not rely on this
module for navigation.

=head1 COPYRIGHT

Copyright (C) 2002-9, Leon Brocard

=head1 LICENSE

This module is free software; you can redistribute it or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Leon Brocard, acme@astray.com.


