#!perl -T

use utf8;
use Modern::Perl;
use Test::Spec;
use YAML::XS;

plan tests => 14;

use Validator::Lazy;

=pod
  first_name   Required   Maximum 64 alphanumeric characters.
  last_name    Required   Maximum 64 alphanumeric characters.
  org_name     Required   Maximum 64 alphanumeric characters.
  address1     Required   Maximum 64 alphanumeric characters.  => address 0..3x64 = 0..192
  address2     Optional   Maximum 64 alphanumeric characters.
  address3     Optional   Maximum 64 alphanumeric characters.
  city         Required   Maximum 64 alphanumeric characters.
  state        Required   if country = CA or US Not required for .NL Maximum 32 alphanumeric characters.
  postal_code  Required   Maximum 16 alphanumeric characters. Note: For .NL, ensure that the postal code does not include any spaces.
  country      Required   2 letter ISO country code.
  phone        Required   Maximum 20 alphanumeric characters, syntax verified according to EPP.
  fax          Optional   Maximum 20 alphanumeric characters, in the format +CCC.NNNNNNNNNNxEEEE, where C = country code, N = phone number, and E = extension (optional).
  email        Required   Maximum 64 characters to left of and 63 characters right of "@" sign, alphanumeric characters, validated according to rfc822.
=cut

my $config = Load q~
    Name:
        - RegExp: '/^[A-Za-z0-9 ,.\/"():;-]+$/'

    ReqName:
        - Required
        - Name

    '/(admin|owner|billing|tech)_(first|last|org)_name/':
        - ReqName
        - MinMax: [ 2, 64 ]

    '/(admin|owner|billing|tech)_address/':
        - ReqName
        - MinMax: [ 8, 192 ]

    '/(admin|owner|billing|tech)_city/':
        - ReqName
        - MinMax: [ 2, 64, 'Str' ]

    '/(admin|owner|billing|tech)_state/':
        - Name
        - MinMax: [ 0, 32 ]

    '/(admin|owner|billing|tech)_postal_code/':
        - Name
        - MinMax: [ 0, 16, 'Str' ]

    '/(admin|owner|billing|tech)_country/':
        - Required
        - CountryCode

    '/(admin|owner|billing|tech)_(phone|fax)/':
        - Phone

    '/(admin|owner|billing|tech)_phone/':
        - Required

    '/(admin|owner|billing|tech)_email/':
        - Required
        - Email

    authinfo:
        - RegExp: '/^[A-Za-z0-9%_!*=;:#\/\\{}&\[\]<>+\$\~`?\|()@^",.-]{8,32}$/'

    gtld:
        - Form:
            - [ 'admin', 'owner', 'billing', 'tech' ] # It will be 4 blocks with these prefixes
            - first_name
            - last_name
            - org_name
            - address
            - city
            - state
            - postal_code
            - country
            - phone
            - fax
            - email
            -              # This ends block with prefixes
            - authinfo
~;



# General TLD
describe 'GTLD role' => sub {

    it 'voidness' => sub {
        my $v = Validator::Lazy->new( $config );

        my $form_data = { };

        my( $ok, $data ) = $v->check( gtld => $form_data );

        my $errors = [
            { code => 'REQUIRED_ERROR', field => 'admin_address',      data => {}, },
            { code => 'REQUIRED_ERROR', field => 'admin_city',         data => {}, },
            { code => 'REQUIRED_ERROR', field => 'admin_country',      data => {}, },
            { code => 'REQUIRED_ERROR', field => 'admin_email',        data => {}, },
            { code => 'REQUIRED_ERROR', field => 'admin_first_name',   data => {}, },
            { code => 'REQUIRED_ERROR', field => 'admin_last_name',    data => {}, },
            { code => 'REQUIRED_ERROR', field => 'admin_org_name',     data => {}, },
            { code => 'REQUIRED_ERROR', field => 'admin_phone',        data => {}, },
            { code => 'REQUIRED_ERROR', field => 'billing_address',    data => {}, },
            { code => 'REQUIRED_ERROR', field => 'billing_city',       data => {}, },
            { code => 'REQUIRED_ERROR', field => 'billing_country',    data => {}, },
            { code => 'REQUIRED_ERROR', field => 'billing_email',      data => {}, },
            { code => 'REQUIRED_ERROR', field => 'billing_first_name', data => {}, },
            { code => 'REQUIRED_ERROR', field => 'billing_last_name',  data => {}, },
            { code => 'REQUIRED_ERROR', field => 'billing_org_name',   data => {}, },
            { code => 'REQUIRED_ERROR', field => 'billing_phone',      data => {}, },
            { code => 'REQUIRED_ERROR', field => 'owner_address',      data => {}, },
            { code => 'REQUIRED_ERROR', field => 'owner_city',         data => {}, },
            { code => 'REQUIRED_ERROR', field => 'owner_country',      data => {}, },
            { code => 'REQUIRED_ERROR', field => 'owner_email',        data => {}, },
            { code => 'REQUIRED_ERROR', field => 'owner_first_name',   data => {}, },
            { code => 'REQUIRED_ERROR', field => 'owner_last_name',    data => {}, },
            { code => 'REQUIRED_ERROR', field => 'owner_org_name',     data => {}, },
            { code => 'REQUIRED_ERROR', field => 'owner_phone',        data => {}, },
            { code => 'REQUIRED_ERROR', field => 'tech_address',       data => {}, },
            { code => 'REQUIRED_ERROR', field => 'tech_city',          data => {}, },
            { code => 'REQUIRED_ERROR', field => 'tech_country',       data => {}, },
            { code => 'REQUIRED_ERROR', field => 'tech_email',         data => {}, },
            { code => 'REQUIRED_ERROR', field => 'tech_first_name',    data => {}, },
            { code => 'REQUIRED_ERROR', field => 'tech_last_name',     data => {}, },
            { code => 'REQUIRED_ERROR', field => 'tech_org_name',      data => {}, },
            { code => 'REQUIRED_ERROR', field => 'tech_phone',         data => {}, },
        ];

        is_deeply(
            [ sort { $a->{field} cmp $b->{field} } @{ $v->errors } ],
            [ sort { $a->{field} cmp $b->{field} } @$errors        ],
        );

        is_deeply(
            $data->{gtld},
            {
                ( map { $_->{field}         => undef } @$errors ),                        # required
                ( map { $_ . '_state'       => undef } qw/ admin owner billing tech / ),  # optional
                ( map { $_ . '_postal_code' => undef } qw/ admin owner billing tech / ),  # optional
                ( map { $_ . '_fax'         => undef } qw/ admin owner billing tech / ),  # optional
                authinfo => undef,
            },
        );
    };

    it 'full data' => sub {

        my $form_data = {
            admin_address       => 'Bee str. 46/78',
            admin_city          => 'London',
            admin_country       => 'US',
            admin_email         => 'john.smith@nowhere.com',
            admin_fax           => '',
            admin_first_name    => 'John',
            admin_last_name     => 'Smith',
            admin_org_name      => 'Another One',
            admin_phone         => '+18665605601',
            admin_postal_code   => '5901',
            admin_state         => '',

            billing_address     => 'Bee str. 46/78',
            billing_city        => 'London',
            billing_country     => 'US',
            billing_email       => 'mike-dough@nowhere.com',
            billing_fax         => '',
            billing_first_name  => 'Mike',
            billing_last_name   => 'Dough',
            billing_org_name    => 'Another One',
            billing_phone       => '+18665605602',
            billing_postal_code => '5901',
            billing_state       => '',

            owner_address       => 'Bee str. 46/78',
            owner_city          => 'London',
            owner_country       => 'US',
            owner_email         => 'kswift@nowhere.com',
            owner_fax           => '',
            owner_first_name    => 'Karen',
            owner_last_name     => 'Swift',
            owner_org_name      => 'Another One',
            owner_phone         => '+18665605603',
            owner_postal_code   => '',
            owner_state         => '',

            tech_address        => 'Bee str. 46/78',
            tech_city           => 'London',
            tech_country        => 'US',
            tech_email          => 'julia@nowhere.com',
            tech_fax            => '',
            tech_first_name     => 'Julia',
            tech_last_name      => 'Flower',
            tech_org_name       => 'Another One',
            tech_phone          => '+18665605604',
            tech_postal_code    => '',
            tech_state          => '',

            authinfo            => '*%$54$%gsd^$#$23',
        };

        my $v = Validator::Lazy->new( $config );
        my( $ok, $data ) = $v->check( gtld => $form_data );
        is_deeply( $v->errors, [] );
        is_deeply( $data->{gtld}, $form_data );

        $form_data->{tech_city} = '';
        ( $ok, $data ) = $v->check( gtld => $form_data );
        is_deeply( $v->errors, [ { code => 'REQUIRED_ERROR', field => 'tech_city', data => {} } ] );
        is_deeply( $data->{gtld}, $form_data );

        $v->errors([]);
        $v->warnings([]);
        $form_data->{tech_city} = 'London';
        $form_data->{admin_fax} = 'London';

        ( $ok, $data ) = $v->check( gtld => $form_data );
        is_deeply( $v->errors, [ { code => 'PHONE_BAD_FORMAT', field => 'admin_fax', data => {} } ] );
        is_deeply( $data->{gtld}, $form_data );
    };


    it 'full multilevel data' => sub {

        my $form_data = {
            admin => {
                address       => 'Bee str. 46/78',
                city          => 'London',
                country       => 'US',
                email         => 'john.smith@nowhere.com',
                fax           => '',
                first_name    => 'John',
                last_name     => 'Smith',
                org_name      => 'Another One',
                phone         => '+18665605601',
                postal_code   => '5901',
                state         => '',
            },

            billing => {
                address     => 'Bee str. 46/78',
                city        => 'London',
                country     => 'US',
                email       => 'mike-dough@nowhere.com',
                fax         => '',
                first_name  => 'Mike',
                last_name   => 'Dough',
                org_name    => 'Another One',
                phone       => '+18665605602',
                postal_code => '5901',
                state       => '',
            },

            owner => {
                address       => 'Bee str. 46/78',
                city          => 'London',
                country       => 'US',
                email         => 'kswift@nowhere.com',
                fax           => '',
                first_name    => 'Karen',
                last_name     => 'Swift',
                org_name      => 'Another One',
                phone         => '+18665605603',
                postal_code   => '',
                state         => '',
            },

            tech => {
                address        => 'Bee str. 46/78',
                city           => 'London',
                country        => 'US',
                email          => 'julia@nowhere.com',
                fax            => '',
                first_name     => 'Julia',
                last_name      => 'Flower',
                org_name       => 'Another One',
                phone          => '+18665605604',
                postal_code    => '',
                state          => '',
            },

            authinfo            => '*%$54$%gsd^$#$23',
        };

        my $config = Load q~
            Name:
                - RegExp: '/^[A-Za-z0-9 ,.\/"():;-]+$/'

            ReqName:
                - Required
                - Name

            '/(first|last|org)_name/':
                - ReqName
                - MinMax: [ 2, 64 ]

            'address':
                - ReqName
                - MinMax: [ 8, 192 ]

            'city':
                - ReqName
                - MinMax: [ 2, 64, 'Str' ]

            'state':
                - Name
                - MinMax: [ 0, 32 ]

            'postal_code':
                - Name
                - MinMax: [ 0, 16, 'Str' ]

            'country':
                - Required
                - CountryCode

            '[phone,fax]':
                - Phone

            'phone':
                - Required

            'email':
                - Required
                - Email

            authinfo:
                - RegExp: '/^[A-Za-z0-9%_!*=;:#\/\\{}&\[\]<>+\$\~`?\|()@^",.-]{8,32}$/'

            '[admin,billing,owner,tech]':
                - Form:
                    - first_name
                    - last_name
                    - org_name
                    - address
                    - city
                    - state
                    - postal_code
                    - country
                    - phone
                    - fax
                    - email

            gtld:
                - Form:
                    - admin
                    - billing
                    - owner
                    - tech
                    - authinfo
        ~;

        my $v = Validator::Lazy->new( $config );

        my( $ok, $data ) = $v->check( gtld => $form_data );
        is_deeply( $v->errors, [] );
        is_deeply( $data->{gtld}, $form_data );

        $form_data->{tech}->{city} = '';
        ( $ok, $data ) = $v->check( gtld => $form_data );

        is_deeply( $v->errors, [ { code => 'REQUIRED_ERROR', field => 'tech_city', data => {} } ] );
        is_deeply( $data->{gtld}, $form_data );

        $v->errors([]);
        $v->warnings([]);
        $form_data->{tech}->{city} = 'London';
        $form_data->{admin}->{fax} = 'London';

        ( $ok, $data ) = $v->check( gtld => $form_data );
        is_deeply( $v->errors, [ { code => 'PHONE_BAD_FORMAT', field => 'admin_fax', data => {} } ] );
        is_deeply( $data->{gtld}, $form_data );

    };
};

runtests unless caller;
