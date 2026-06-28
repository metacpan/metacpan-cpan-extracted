#!perl
use strictures 2;

use Test2::V1               qw( is ok subtest done_testing );
use Test2::Tools::Exception qw( dies lives );

use WebService::OPNsense::Normalize qw( normalize_ip validate_uuid );

subtest 'normalize_ip' => sub {

    subtest 'NetAddr::IP' => sub {
        use NetAddr::IP ();
        my $ip = NetAddr::IP->new('192.0.2.0/24');
        is( normalize_ip($ip), '192.0.2.0/24', 'NetAddr::IP' );
    };

    subtest 'Net::Netmask' => sub {
        use Net::Netmask ();
        my $ip = Net::Netmask->new('10.0.0.0/8');
        is( normalize_ip($ip), '10.0.0.0/8', 'Net::Netmask' );
    };

    subtest 'Net::CIDR::Lite' => sub {
        subtest 'single range' => sub {
            use Net::CIDR::Lite ();
            my $lite = Net::CIDR::Lite->new;
            $lite->add('172.16.0.0/12');
            is( normalize_ip($lite), '172.16.0.0/12', 'single range' );
        };

        subtest 'multi-range dies' => sub {
            use Net::CIDR::Lite ();
            my $lite = Net::CIDR::Lite->new;
            $lite->add('10.0.0.0/8');
            $lite->add('192.0.2.0/24');
            ok( dies { normalize_ip($lite) }, 'multi-range dies' );
        };

        subtest 'empty dies' => sub {
            use Net::CIDR::Lite ();
            my $lite = Net::CIDR::Lite->new;
            ok( dies { normalize_ip($lite) }, 'empty dies' );
        };
    };

    subtest 'invalid inputs' => sub {
        subtest 'unsupported class' => sub {
            my $fake = bless {}, 'Unknown::Class';
            ok( dies { normalize_ip($fake) }, 'Unknown class dies' );
        };

        subtest 'undef' => sub {
            ok( dies { normalize_ip(undef) }, 'undef dies' );
        };

        subtest 'non-blessed scalar' => sub {
            ok( dies { normalize_ip('plain string') }, 'non-blessed scalar dies' );
        };

        subtest 'non-blessed hashref' => sub {
            ok( dies { normalize_ip( {} ) }, 'non-blessed hashref dies' );
        };
    };

    subtest 'IPv6 via NetAddr::IP' => sub {
        use NetAddr::IP ();
        my $ip = NetAddr::IP->new('2001:db8:1::/48');

        is( normalize_ip($ip), '2001:DB8:1:0:0:0:0:0/48', 'IPv6 expanded' );
    };
};

subtest 'validate_uuid' => sub {

    subtest 'valid UUIDs' => sub {
        subtest 'v4 with dashes' => sub {
            ok(
                lives { validate_uuid('550e8400-e29b-41d4-a716-446655440000') },
                'valid UUID v4'
            );
        };

        subtest 'v4 with dashes (alt)' => sub {
            ok(
                lives { validate_uuid('f47ac10b-58cc-4372-a567-0e02b2c3d479') },
                'valid UUID v4 (alt)'
            );
        };

        subtest 'v1 with dashes' => sub {
            ok(
                lives { validate_uuid('c1e7a4b0-bf1c-11e9-8f0b-362b9e155667') },
                'valid UUID v1'
            );
        };
    };

    subtest 'invalid inputs' => sub {
        subtest 'path traversal' => sub {
            ok(
                dies { validate_uuid('/../etc/passwd') },
                'path traversal dies'
            );
        };

        subtest 'non-UUID string' => sub {
            ok(
                dies { validate_uuid('hello') },
                'non-UUID string dies'
            );
        };

        subtest 'non-hex char' => sub {
            ok(
                dies { validate_uuid('550e8400-e29b-41d4-a716-44665544000Z') },
                'non-hex char dies'
            );
        };

        subtest 'empty string' => sub {
            ok(
                dies { validate_uuid(q{}) },
                'empty string dies'
            );
        };

        subtest 'undef' => sub {
            ok(
                dies { validate_uuid(undef) },
                'undef dies'
            );
        };

        subtest 'whitespace-only string' => sub {
            ok(
                dies { validate_uuid(q{  }) },
                'whitespace-only string dies'
            );
        };
    };
};

done_testing;
