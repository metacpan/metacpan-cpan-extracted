# -*- perl -*-

# t/002_parsecosmosxml.t - checks loading cosmos api query and results parsing

use Test::More tests => 5;
use XML::XPath;
use XML::Parser;
use WebService::Technorati;
use FindBin qw($Bin);

my $apiKey = 'a_key_that_wont_work_with_a_live_query';
my $url = 'http://www.arachna.com/roller/page/spidaman';
my $t = WebService::Technorati->new(key => $apiKey);
my $cq = $t->getCosmosApiQuery($url);

my $parser = new XML::Parser(NoLWP => 1);
my $result_xp = XML::XPath->new(
    parser => $parser,
    filename => "$Bin/testdata/cosmos.xml");
$cq->readResults($result_xp);

my $linkquery = $cq->getLinkQuerySubject();
isa_ok($linkquery, 'WebService::Technorati::LinkQuerySubject');
my @links = $cq->getInboundLinks();
is(19, $#links);
my $link = pop(@links);
isa_ok($link, 'WebService::Technorati::BlogLink');


$result_xp = XML::XPath->new(
    parser => $parser,
    filename => "$Bin/testdata/cosmos-nonblog.xml");
$linkquery = $cq->getLinkQuerySubject();
isa_ok($linkquery, 'WebService::Technorati::LinkQuerySubject');
@links = $cq->getInboundLinks();
is(19, $#links);

