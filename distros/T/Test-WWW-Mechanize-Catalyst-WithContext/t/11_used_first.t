use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib 't/lib';

BEGIN {
    $ENV{CATALYST_DEBUG} = 0;
    $ENV{CATTY_DEBUG}    = 0;
}
use Test::WWW::Mechanize::Catalyst::WithContext 'Catty';

my $mech = Test::WWW::Mechanize::Catalyst::WithContext->new;
my ( $res, $c );
lives_ok { ( $res, $c ) = $mech->get_context('/') } 'Grabbing a context directly lives';

isa_ok $res, 'HTTP::Response', '$res';
is $res->code, 200, '... and request was successful';

isa_ok $c, 'Catalyst', '$c';
isa_ok $c, 'Catty',    '$c';

done_testing;
