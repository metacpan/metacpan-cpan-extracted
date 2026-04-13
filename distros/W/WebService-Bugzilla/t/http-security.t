#!perl
use strict;
use warnings;
use Test::More import => [qw(done_testing ok diag subtest)];
use lib 'lib', 't/lib';

use WebService::Bugzilla;

sub dies_ok (&) {
    my ($code) = @_;
    my $err;
    { local $@; eval { $code->() }; $err = $@ }
    ok($err, 'died as expected');
}

subtest 'HTTPS allowed' => sub {
    my $bz = WebService::Bugzilla->new(
        base_url => 'https://bugzilla.example.com',
        api_key  => 'test',
    );
    ok($bz, 'HTTPS URL accepted');
};

subtest 'localhost HTTP allowed' => sub {
    my $bz = WebService::Bugzilla->new(
        base_url => 'http://localhost',
        api_key  => 'test',
    );
    ok($bz, 'localhost HTTP accepted');
};

subtest 'localhost with port HTTP allowed' => sub {
    my $bz = WebService::Bugzilla->new(
        base_url => 'http://localhost:8080',
        api_key  => 'test',
    );
    ok($bz, 'localhost:8080 HTTP accepted');
};

subtest '127.x.x.x HTTP allowed' => sub {
    my $bz = WebService::Bugzilla->new(
        base_url => 'http://127.0.0.1',
        api_key  => 'test',
    );
    ok($bz, '127.0.0.1 HTTP accepted');
};

subtest '127.x.x.x with port HTTP allowed' => sub {
    my $bz = WebService::Bugzilla->new(
        base_url => 'http://127.0.0.1:8080',
        api_key  => 'test',
    );
    ok($bz, '127.0.0.1:8080 HTTP accepted');
};

subtest '::1 (IPv6 localhost) HTTP allowed' => sub {
    my $bz = WebService::Bugzilla->new(
        base_url => 'http://[::1]',
        api_key  => 'test',
    );
    ok($bz, 'IPv6 localhost HTTP accepted');
};

subtest '::1 with port (IPv6 localhost) HTTP allowed' => sub {
    my $bz = WebService::Bugzilla->new(
        base_url => 'http://[::1]:8080',
        api_key  => 'test',
    );
    ok($bz, 'IPv6 localhost with port HTTP accepted');
};

subtest 'External HTTP refused by default' => sub {
    dies_ok {
        WebService::Bugzilla->new(
            base_url => 'http://bugzilla.example.com',
            api_key  => 'test',
        );
    };
};

subtest 'External HTTP allowed with allow_http' => sub {
    my $bz = WebService::Bugzilla->new(
        base_url   => 'http://bugzilla.example.com',
        api_key    => 'test',
        allow_http => 1,
    );
    ok($bz, 'allow_http overrides HTTP check');
};

subtest 'Non-standard port on localhost HTTP allowed' => sub {
    my $bz = WebService::Bugzilla->new(
        base_url => 'http://localhost:3000/bugzilla',
        api_key  => 'test',
    );
    ok($bz, 'localhost with non-standard port accepted');
};

done_testing();
