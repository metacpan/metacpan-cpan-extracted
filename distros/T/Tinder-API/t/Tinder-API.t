# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Tinder-API.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::Simple tests => 2;
use Tinder::API;

#########################
my $Id='123';
my $Token="567";
my $API=Tinder::API->new($Token,$Id);
ok( $API->getFbToken() == $Token );
ok( $API->getId() == $Id );

