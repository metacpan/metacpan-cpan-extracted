use strict;
use warnings;

use Test2::V0;

use Unblock::HTTP3;
use Unblock::HTTP3::Body::Reader;
use Unblock::HTTP3::Body::Stream;
use Unblock::HTTP3::Capsule;
use Unblock::HTTP3::Capsule::Parser;
use Unblock::HTTP3::Capsule::Stream;
use Unblock::HTTP3::Connection;
use Unblock::HTTP3::Extension::Stream;
use Unblock::HTTP3::Request;
use Unblock::HTTP3::Response;
use Unblock::HTTP3::Transaction;
use Unblock::HTTP3::_Bytes;
use Unblock::HTTP3::_Native;

pass('Unblock::HTTP3 modules load');

my @versioned_modules = (
    [ 'Unblock::HTTP3',               $Unblock::HTTP3::VERSION ],
    [ 'Unblock::HTTP3::Body::Reader', $Unblock::HTTP3::Body::Reader::VERSION ],
    [ 'Unblock::HTTP3::Body::Stream', $Unblock::HTTP3::Body::Stream::VERSION ],
    [ 'Unblock::HTTP3::Capsule',      $Unblock::HTTP3::Capsule::VERSION ],
    [ 'Unblock::HTTP3::Capsule::Parser', $Unblock::HTTP3::Capsule::Parser::VERSION ],
    [ 'Unblock::HTTP3::Capsule::Stream', $Unblock::HTTP3::Capsule::Stream::VERSION ],
    [ 'Unblock::HTTP3::Connection',   $Unblock::HTTP3::Connection::VERSION ],
    [ 'Unblock::HTTP3::Extension::Stream', $Unblock::HTTP3::Extension::Stream::VERSION ],
    [ 'Unblock::HTTP3::Request',      $Unblock::HTTP3::Request::VERSION ],
    [ 'Unblock::HTTP3::Response',     $Unblock::HTTP3::Response::VERSION ],
    [ 'Unblock::HTTP3::Transaction',  $Unblock::HTTP3::Transaction::VERSION ],
    [ 'Unblock::HTTP3::_Bytes',       $Unblock::HTTP3::_Bytes::VERSION ],
    [ 'Unblock::HTTP3::_Native',      $Unblock::HTTP3::_Native::VERSION ],
);

for my $module (@versioned_modules) {
    is($module->[1], '0.01', "$module->[0] version matches distribution");
}

done_testing;
