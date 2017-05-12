# $Id: 01load.t,v 1.1 2003/11/11 22:49:12 struan Exp $

use Test::More tests => 3;

use_ok( 'WebService::Validator::HTML::W3C' );

my $v = WebService::Validator::HTML::W3C->new;

ok($v, 'Object created');

isa_ok($v, 'WebService::Validator::HTML::W3C');
