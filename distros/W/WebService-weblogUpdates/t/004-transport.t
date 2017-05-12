use strict;
use Test::More;

#

eval "require SOAP::Lite";

if ($@) {
   plan tests => 1;

   warn 
     "You do not have the SOAP::Lite package installed\n".
     "You will not be able to ping the weblogUpdates service using the SOAP protocol.\n";

   ok(1);
   exit;
}

#

plan tests => 8;

use constant PACKAGE       => "WebService::weblogUpdates";
use constant PINGNAME      => "Perlblog";
use constant PINGURL       => "http://www.nospum.net/perlblog";

use constant RSSUPDATENAME => "What does Aaron think about RSS";
use constant RSSUPDATEURL  => "http://aaronland.info/weblog/category/rss/rss";

ok($SOAP::Lite::VERSION >= 0.55,"SOAP::Lite::VERSION >= 0.55");

use_ok("WebService::weblogUpdates");

my $weblogs = WebService::weblogUpdates->new(transport=>"SOAP",debug=>1);
isa_ok($weblogs,PACKAGE,PACKAGE);

ok($weblogs->ping({name=>PINGNAME,url=>PINGURL}),"pinged for:".PINGURL);

my $msg = $weblogs->LastMessage();
ok($msg,$msg);

ok($weblogs->Transport("XMLRPC"),"Switched transport mechanism to XML-RPC");

ok($weblogs->rssUpdate({name=>RSSUPDATENAME,url=>RSSUPDATEURL}),
   "old-skool ping for RSS feed:".RSSUPDATEURL);	

my $msg = $weblogs->LastMessage();
ok($msg,$msg);
