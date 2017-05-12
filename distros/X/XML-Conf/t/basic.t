#!/usr/local/bin/perl -w

# $Id: basic.t,v 1.3 2003/02/03 15:36:27 jonasbn Exp $

use strict;
use Test::More tests => 13;
use Data::Dumper;

my $debug = 0;

#test 1 and 2
BEGIN { use_ok( 'XML::Conf' ); }
require_ok('XML::Conf');

my $c = XML::Conf->new('t/populated.xml');

print STDERR Dumper $c if $debug;

my ($v, $w);

#test 3
ok($v = $c->NEXTKEY(), 'A test of the NEXTKEY method, we are on the first element in the configuration');

#test 4
$w = $c->FIRSTKEY();
ok($v eq $w, 'A test of the FIRSTKEY and NEXTKEY methods, the two values should be similar');

#test 5
$v = $c->NEXTKEY();
ok($v ne $w, 'A test of the NEXTKEY method, should not be similar to the FIRSTKEY call (above)');

#test 6
ok($v = $c->FIRSTKEY(), 'A test of the FIRSTKEY method, we just go back to the beginning');

#test 7
$w = $c->NEXTKEY();
ok($v ne $w, 'A test of the NEXTKEY method, second element, we just move along in the tree');

#test 8
$v = $c->NEXTKEY();
ok($v ne $w, 'A test of the NEXTKEY method, third element, we just move along in the tree');

#test 9
ok($c->EXISTS($v), 'A test of the EXISTS method, asking for the existance of the element we just assured the existance of with the NEXTKEY method above');

#test 10
ok($c->DELETE($v), 'A test of the DELETE method, deleting the element we just assured was there');

#test 11
ok((! $c->EXISTS($v)), 'A test of the EXISTS method, checking for existance of the newly deleted element (should fail)');

#test 12
ok($c->CLEAR(), 'A test of the CLEAR method, flushing the configuration');

#test 13
ok((! $c->FIRSTKEY), 'A test of the FIRSTKEY method after having cleared the contents (should fail)');