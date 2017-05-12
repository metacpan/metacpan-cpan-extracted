#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use WebService::Box;

my $box = WebService::Box->new;

my ($before,$after) = (""," is a read-only accessor");
if ( $INC{"Class/XSAccessor.pm"} ) {
    $before = "Usage: WebService::Box::";
    $after  = '\(self\)';
}

throws_ok
    { $box->api_url( 'test' ) }
    qr/${before}api_url$after/,
    'api_url is a read-only accessor';

throws_ok
    { $box->upload_url( 'test' ) }
    qr/${before}upload_url$after/,
    'upload_url is a read-only accessor';

throws_ok
    { $box->on_error( 'die' ) }
    qr/${before}on_error$after/,
    'on_error is a read-only accessor';

done_testing();
