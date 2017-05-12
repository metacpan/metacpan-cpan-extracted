use strict;
use Test::More;

eval "require LWP::Simple";

if ($@) {
   plan tests => 1;

   warn 
     "You do not have the LWP::Simple package installed\n".
     "You will not be able to ping the weblogUpdates service using the REST protocol.\n";

   ok(1);
   exit;
}

plan tests => 6;

use constant PACKAGE  => "WebService::weblogUpdates";
use constant PINGNAME => "Perlblog";
use constant PINGURL  => "http://www.nospum.net/perlblog";

use_ok("WebService::weblogUpdates");

my $weblogs = WebService::weblogUpdates->new(transport=>"REST",debug=>0);
isa_ok($weblogs,PACKAGE);

ok($weblogs->ping({name=>PINGNAME,url=>PINGURL}),"ping for ".PINGURL);

my $msg = $weblogs->LastMessage();
ok($msg,$msg);

ok($weblogs->ping({name=>PINGNAME,url=>PINGURL,changesurl=>PINGURL}),
   "pinged with changes for ".PINGURL);

ok($msg,$msg);
