#!/usr/local/bin/perl -w

use strict;
use Test::More tests => 13;
use Data::Dumper;

# $Id: private.t,v 1.4 2003/12/09 19:12:28 jonasbn Exp $

my $debug = 0;

#test 1-2
BEGIN { use_ok( 'XML::Conf' ); }
require_ok('XML::Conf');

my $config = XML::Conf->new('t/populated.xml');

print STDERR Dumper $config if $debug;

#test 3
my @listcontext = $config->_val();
ok(@listcontext, 'A test of the _val method in list context');

#test 4-5
my $scalarcontext = $config->_val();
ok($scalarcontext, 'A test of the _val method in scalar context');
is(ref($scalarcontext), 'HASH', 'Checking the returned value');

#test 6-7
ok($config->_setval('newvalue', 'testvalue'), 'A test of the _setval method');
is($config->_val("newvalue"), 'testvalue', 'A test of the _val method (asserting the _setval');

#test 8-9
ok($config->_setval('newvalue1', 'newvalue2', 'testvalue'), 'A test of the _setval method');
is($config->_val("newvalue1", 'newvalue2'), 'testvalue', 'A test of the _val method (asserting the _setval)');

#test 10-11
ok($config->_delval('newvalue1', 'newvalue2'), 'A test of the _delval method');
is($config->_val('newvalue1', 'newvalue2'), undef, 'A test of the _val method (asserting the _delval)');

#test 12-13
$config->_setval('newvalue1', 'newvalue2', 'testvalue');
ok($config->_delval('newvalue1'), 'A test of the _delval method');
is($config->_val('newvalue1'), undef, 'A test of the _val method (asserting the _delval)');

print STDERR Dumper $config if $debug;
