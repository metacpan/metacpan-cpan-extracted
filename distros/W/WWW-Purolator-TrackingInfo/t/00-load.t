#!perl -T
use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
    use_ok('LWP::UserAgent');
    use_ok('JSON::PP');
    use_ok('Class::Accessor::Grouped');
    use_ok( 'WWW::Purolator::TrackingInfo' );
}

diag( "Testing WWW::Purolator::TrackingInfo $WWW::Purolator::TrackingInfo::VERSION, Perl $], $^X" );

