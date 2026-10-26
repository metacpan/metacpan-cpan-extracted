use strict;
use warnings;
use Test::More;

use_ok('Unblock::HTTP');
use_ok('Unblock::HTTP::Client');
use_ok('Unblock::HTTP::_ClientOperation');
use_ok('Unblock::HTTP::_AltSvc');
use_ok('Unblock::HTTP::Server');
use_ok('Unblock::HTTP::Integration');
use_ok('Unblock::HTTP::QUIC');

is($Unblock::HTTP::VERSION, '0.03', 'distribution version');
for my $module (qw(
    Unblock::HTTP::Client
    Unblock::HTTP::Server
    Unblock::HTTP::Integration
    Unblock::HTTP::QUIC
)) {
    no strict 'refs';
    is(${"${module}::VERSION"}, $Unblock::HTTP::VERSION,
        "$module package version matches distribution");
}
done_testing;
