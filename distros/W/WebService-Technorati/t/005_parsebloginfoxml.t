# -*- perl -*-

# t/005_parsebloginfoxml.t - checks loading bloginfo api query and results parsing

use Test::More tests => 1;
use XML::XPath;
use XML::Parser;
use WebService::Technorati;
use FindBin qw($Bin);

my $apiKey = 'a_key_that_wont_work_with_a_live_query';
my $url = 'http://www.arachna.com/roller/page/spidaman';
my $t = WebService::Technorati->new(key => $apiKey);
my $q = $t->getBloginfoApiQuery($url);

my $parser = new XML::Parser(NoLWP => 1);
my $result_xp = XML::XPath->new(
    parser => $parser,
    filename => "$Bin/testdata/bloginfo.xml");
$q->readResults($result_xp);

my $blog = $q->getSubjectBlog();
isa_ok($blog, 'WebService::Technorati::Blog');

