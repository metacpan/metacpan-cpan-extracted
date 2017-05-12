use Test::Modern;
use t::lib::Harness qw(ss);
plan skip_all => 'Invalid SmartyStreets credentials' unless defined ss();

use Storable qw(dclone);

subtest 'Testing verify_address parameter errors' => sub {
    my %address_params = (
        street  => '370 Townsend St',
        city    => 'San Francisco',
        state   => 'CA',
    );

    for my $key (keys %address_params) {
        my %params = %{ dclone(\%address_params) };
        delete $params{$key};
        like exception { ss->verify_address(%params) },
            qr/missing required argument \$$key/,
            "failed correctly on missing parameter: $key";
    }
};

subtest 'Testing verify_address address errors' => sub {
    isa_ok exception { ss->verify_address(
        street  => '370 Townsend St',
        city    => 'Boulder',
        state   => 'CO',
        zipcode => '80305',
    )}, 'WebService::SmartyStreets::Exception::AddressNotFound';

    isa_ok exception { ss->verify_address(
        street  => '1529 Queen Anne Ave N',
        city    => 'Seattle',
        state   => 'WA',
        zipcode => '98109',
    )}, 'WebService::SmartyStreets::Exception::AddressMissingInformation';
};

subtest 'Testing verify_address address lookup' => sub {
    my $addresses = ss->verify_address(
        street  => '370 Townsend St',
        city    => 'San Francisco',
        state   => 'CA',
        zipcode => '94107',
    );

    cmp_deeply $addresses => [{
            city    => 'San Francisco',
            state   => 'CA',
            street  => '370 Townsend St',
            zipcode => '94107-1607',
        }], 'successful simple address lookup'
        or diag explain $addresses;

    #$addresses = ss->verify_address(
    #    street     => '1109 9th',
    #    street2    => '#123',
    #    city       => 'Phoenix',
    #    state      => 'AZ',
    #    zipcode    => '',
    #    candidates => 2,
    #);
    #
    #cmp_deeply $addresses => [{
    #        city    => 'Phoenix',
    #        state   => 'AZ',
    #        street  => '1109 N 9th St # 123',
    #        zipcode => '85006-2734',
    #    },
    #    {
    #        city    => 'Phoenix',
    #        state   => 'AZ',
    #        street  => '1109 S 9th Ave # 123',
    #        zipcode => '85007-3646',
    #    }], 'successful corrective address lookup'
    #    or diag explain $addresses;
};

done_testing;
