#!perl
#
use strict;
use warnings;

use Test::More;
use Test::WWW::Mechanize::PSGI;

my $ua = Test::WWW::Mechanize::PSGI->new(
    app => sub {
        my $env = shift;
        return [ 200, [ 'Content-Type' => 'text/plain' ], ['Hello World'] ],;
    },
);

my @phases = (
    'request_preprepare',
    'request_prepare',
    'request_send',
    'response_header',
    'response_data',
    'response_done',
    'response_redirect',
);

my $slot = 0;
for my $phase (@phases) {
    $ua->add_handler(
        $phase => sub {
            $ENV{ phase_to_env($phase) } = $slot;
            $slot++;
            return undef;
        }
    );
}

for my $phase (@phases) {
    my $var = phase_to_env($phase);
    ok( !exists $ENV{ phase_to_env($phase) }, "handler $phase not yet run" );
}

$ua->get_ok('/');

for my $phase (@phases) {
    subtest $phase => sub {
        my $name = phase_to_env($phase);
        ok( exists $ENV{$name}, 'handler fired' );
        my $slot = $ENV{$name};
        is(
            $phase, $phases[$slot],
            'handler fired in correct order'
        );
    };
}

sub phase_to_env {
    my $phase = shift;
    return 'LWP_' . uc($phase);
}

done_testing();
