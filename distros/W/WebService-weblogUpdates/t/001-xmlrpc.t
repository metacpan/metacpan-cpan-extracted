use strict;
use Test::More;

#

eval "require Frontier::Client";

if ($@) {
   plan tests => 1;

   warn 
     "You do not have the Frontier::RPC package installed\n".
     "You will not be able to ping the weblogUpdates service using the XMLRPC protocol.\n";

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

use_ok("WebService::weblogUpdates");

my $weblogs = WebService::weblogUpdates->new(transport=>"XMLRPC",debug=>1);
isa_ok($weblogs,PACKAGE);

#

ok($weblogs->ping({name=>PINGNAME,url=>PINGURL}),"ping!");

my $msg = $weblogs->LastMessage();
ok($msg,$msg);

#

ok($weblogs->ping({name=>RSSUPDATENAME,url=>RSSUPDATEURL,changesurl=>RSSUPDATEURL,category=>"rss"}),
   "old-skool ping for RSS feed:".RSSUPDATEURL);

my $msg = $weblogs->ping_message();
ok($msg,$msg);

#

ok($weblogs->rssUpdate({name=>RSSUPDATENAME,url=>RSSUPDATEURL}),
   "new-skool ping for RSS feed:".RSSUPDATEURL);

my $msg = $weblogs->LastMessage();
ok($msg,$msg);
