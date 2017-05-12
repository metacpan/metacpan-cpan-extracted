#!perl

use strict;
use warnings;

use File::HomeDir;
use Test::More tests => 5;

BEGIN { use_ok( 'WebService::TVDB::Languages', qw($languages) ); }

ok( $languages, '$languages is exported' );

SKIP: {
    my $api_key_file = File::HomeDir->my_home . '/.tvdb';
    skip 'may not have languages if automated testing', 3
      unless -e $api_key_file;

    ok( $languages->{English}, ' we have English ' );
    is( $languages->{English}->{id}, ' 7 ', ' English has an id ' );
    is( $languages->{English}->{abbreviation},
        ' en ', ' English has an abbreviation ' );
}
