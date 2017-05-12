use Test::Simple 'no_plan';
use strict;
use lib './lib';
require './t/test.pl';
use WordPress::XMLRPC;
no strict 'refs';
use Smart::Comments '###';
ok(1,'starting test.');


assure_fulltesting();

$WordPress::XMLRPC::DEBUG = 1;
my $w = WordPress::XMLRPC->new(_conf('./t/wppost'));

for my $method (qw/getPageTemplates setTemplate getTemplate/){
   ok $w->can($method), "can $method()";
}

my $r;

ok( $r = $w->getPageTemplates, 'getPageTemplates()');

### return: $r



my @names = keys %$r;
### template names : @names


my $TEST_FULL = 0;
unless( $TEST_FULL ){
   warn("skipping getTemplate, needs to be worked out.");
   exit;
}



ok( ! eval{ $w->getTemplate } , 'getTemplate() without arg fails');

for my $template_name (@names){
   ok( $r = $w->getTemplate($template_name), "getTemplate() $template_name" );
   ### getTemplate : $r
}


