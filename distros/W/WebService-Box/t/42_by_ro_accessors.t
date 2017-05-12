#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WebService::Box::Types::By;

my $box = WebService::Box::Types::By->new(
    id     => 123,
    login  => 'abcdef',
    name   => 'affe0815',
    type   => 'user',
);

my ($before,$after) = (""," is a read-only accessor");
if ( $INC{"Class/XSAccessor.pm"} ) {
    $before = "Usage: WebService::Box::Types::By::";
    $after  = '\(self\)';
}

for my $method ( qw/id login name type/ ) {
    throws_ok
        { $box->$method( 'test' ) }
        qr/$before$method$after/,
        $method . ' is a read-only accessor';
}

done_testing();
