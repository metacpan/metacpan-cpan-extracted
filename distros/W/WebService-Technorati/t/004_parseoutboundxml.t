# -*- perl -*-

# t/002_parsecosmosxml.t - checks loading cosmos api query and results parsing

use Test::More tests => 3;
use XML::XPath;
use XML::Parser;
use WebService::Technorati;
use FindBin qw($Bin);

my $apiKey = 'a_key_that_wont_work_with_a_live_query';
my $url = 'http://www.arachna.com/roller/page/spidaman';
my $t = WebService::Technorati->new(key => $apiKey);
my $q = $t->getOutboundApiQuery($url);

my $parser = new XML::Parser(NoLWP => 1);
my $result_xp = XML::XPath->new(
    parser => $parser,
    filename => "$Bin/testdata/outbound.xml");
$q->readResults($result_xp);

my $subject = $q->getLinkQuerySubject();
isa_ok($subject, 'WebService::Technorati::LinkQuerySubject');
my @links = $q->getOutboundLinks();
is(19, $#links);
my $link = pop(@links);
isa_ok($link, 'WebService::Technorati::BlogLink');



