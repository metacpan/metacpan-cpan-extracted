#!/usr/bin/env perl

use 5.006;
use strict;
use warnings;

use Test::More;
use Test::More::UTF8;

our $VERSION = '0.02';

BEGIN {
    use_ok( 'WWW::Mechanize::Chrome::Webshot' ) || print "Bail out!\n";
}

diag( "Testing WWW::Mechanize::Chrome::Webshot $WWW::Mechanize::Chrome::Webshot::VERSION, Perl $], $^X" );

done_testing();
