use strict;
use warnings;
use Test::More;

use Unblock::HTTP2;
use Unblock::HTTP2::Client;
use Unblock::HTTP2::NativeABI;
use Unblock::HTTP2::Server;
use Unblock::HTTP2::Transaction;
use Unblock::HTTP2::_Connection;
use Unblock::HTTP2::_Headers;
use Unblock::HTTP2::_nghttp2;

my $version = $Unblock::HTTP2::VERSION;

is $version, '0.10', 'distribution version is 0.10';

for my $module (
    [ 'Unblock::HTTP2::Client',      $Unblock::HTTP2::Client::VERSION ],
    [ 'Unblock::HTTP2::NativeABI',   $Unblock::HTTP2::NativeABI::VERSION ],
    [ 'Unblock::HTTP2::Server',      $Unblock::HTTP2::Server::VERSION ],
    [ 'Unblock::HTTP2::Transaction', $Unblock::HTTP2::Transaction::VERSION ],
    [ 'Unblock::HTTP2::_Connection', $Unblock::HTTP2::_Connection::VERSION ],
    [ 'Unblock::HTTP2::_Headers',    $Unblock::HTTP2::_Headers::VERSION ],
    [ 'Unblock::HTTP2::_nghttp2',    $Unblock::HTTP2::_nghttp2::VERSION ],
) {
    is $module->[1], $version, "$module->[0] version matches distribution";
}

done_testing;
