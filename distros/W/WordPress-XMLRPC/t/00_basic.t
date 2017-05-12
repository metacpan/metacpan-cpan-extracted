use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';

use WordPress::XMLRPC;
no strict 'refs';

ok(1,'starting test.');


assure_fulltesting();



### BASIC SERVER/MODULE TEST

my $w = WordPress::XMLRPC->new(_conf('./t/wppost'));
ok($w,'object instanced') or die;

ok( $w->password,'password()');
ok( $w->username,'username()');
ok( $w->proxy,'proxy()');
ok( $w->blog_id,'blog_id()');

ok( $w->server,'server()');

ok( $w->xmlrpc_methods, 'xmlrpc_methods()');




