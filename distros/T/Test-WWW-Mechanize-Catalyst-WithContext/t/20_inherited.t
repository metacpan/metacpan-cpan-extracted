use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';

BEGIN {
    $ENV{CATALYST_DEBUG} = 0;
    $ENV{CATTY_DEBUG}    = 0;
}
use Test::WWW::Mechanize::Catalyst::WithContext;

my $mech = Test::WWW::Mechanize::Catalyst::WithContext->new( catalyst_app => 'Catty' );
$mech->get_ok('/');
$mech->post_ok('/');

done_testing;
