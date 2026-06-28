#!perl
use strictures 2;

use Test2::V1               qw( is ok like subtest done_testing );
use Test2::Tools::Exception qw( dies );
use Test::LWP::UserAgent    ();

# Set VERSION before loading the main module so BUILD does not warn
BEGIN { $WebService::OPNsense::VERSION = '0.001' }
use WebService::OPNsense ();

# Helper: build a test OPNsense object
sub _build_opn {
    my ($base_url) = @_;
    $base_url //= 'https://opnsense.example.com';
    my $ua  = Test::LWP::UserAgent->new;
    my $opn = WebService::OPNsense->new(
        base_url => $base_url,
        username => 'key',
        password => 'secret',
        ua       => $ua,
    );
    return ( $opn, $ua );
}

## no critic (Subroutines::ProtectPrivateSubs)
subtest '_uri_authority' => sub {
    subtest 'valid URLs' => sub {
        my $auth = WebService::OPNsense->_uri_authority('https://opnsense.example.com:8443');
        is( $auth, 'opnsense.example.com:8443', 'authority with port' );

        $auth = WebService::OPNsense->_uri_authority('https://192.0.2.1');
        is( $auth, '192.0.2.1', 'authority without port' );

        $auth = WebService::OPNsense->_uri_authority('http://localhost/api/v1');
        is( $auth, 'localhost', 'authority with path' );

        $auth = WebService::OPNsense->_uri_authority('http://[::1]:8080/path');
        is( $auth, '[::1]:8080', 'authority IPv6 with port' );
    };

    subtest 'unparseable URLs croak' => sub {
        ok(
            dies { WebService::OPNsense->_uri_authority('not-a-url') },
            'unparseable URL dies'
        );

        ok(
            dies { WebService::OPNsense->_uri_authority(q{}) },
            'empty URL dies'
        );

        ok(
            dies { WebService::OPNsense->_uri_authority('http://') },
            'scheme-only URL dies'
        );
    };
};
## use critic

subtest 'BUILD: trailing-slash strip' => sub {
    subtest 'single trailing slash' => sub {
        my ($opn) = _build_opn('https://opnsense.example.com/');
        is(
            $opn->base_url, 'https://opnsense.example.com',
            'trailing slash stripped'
        );
    };

    subtest 'no trailing slash unchanged' => sub {
        my ($opn) = _build_opn('https://opnsense.example.com');
        is(
            $opn->base_url, 'https://opnsense.example.com',
            'no trailing slash unchanged'
        );
    };

    subtest 'multiple trailing slashes stripped' => sub {
        my ($opn) = _build_opn('https://opnsense.example.com///');
        is(
            $opn->base_url, 'https://opnsense.example.com',
            'multiple trailing slashes stripped'
        );
    };
};

subtest 'BUILD: credentials' => sub {
    my ( undef, $ua ) = _build_opn;
    my $creds = $ua->credentials('opnsense.example.com');
    is( $creds, 'key:secret', 'credentials set on UA' );
};

subtest 'BUILD: User-Agent header' => sub {
    my ( undef, $ua ) = _build_opn;
    my $ua_header = $ua->default_header('User-Agent');
    ok( defined $ua_header, 'User-Agent default header set' );
    like(
        $ua_header, qr/^WebService::OPNsense /,
        'User-Agent starts with module name'
    );
    like(
        $ua_header, qr/perl v[\d.]+/,
        'User-Agent contains perl version'
    );
};

done_testing;
