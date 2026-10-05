use strict;
use warnings;
use Test::More;

use Unblock::HTTP1;
use Unblock::HTTP1::Client;
use Unblock::HTTP1::NativeABI;
use Unblock::HTTP1::Server;
use Unblock::HTTP1::Transaction;

my $version = $Unblock::HTTP1::VERSION;

is $version, '0.10', 'distribution version is 0.10';

for my $module (
    [ 'Unblock::HTTP1::Client',      $Unblock::HTTP1::Client::VERSION ],
    [ 'Unblock::HTTP1::NativeABI',   $Unblock::HTTP1::NativeABI::VERSION ],
    [ 'Unblock::HTTP1::Server',      $Unblock::HTTP1::Server::VERSION ],
    [ 'Unblock::HTTP1::Transaction', $Unblock::HTTP1::Transaction::VERSION ],
) {
    is $module->[1], $version, "$module->[0] version matches distribution";
}

done_testing;
