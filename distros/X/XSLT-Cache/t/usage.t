use strict;
use XSLT::Cache;
use XML::LibXML;
use Test::More qw(no_plan);

my $tr = new XSLT::Cache;

my $xmlparser = new XML::LibXML;

# No time cacheing.

cp('t/xsl/test1.xsl', 't/xsl/test.xsl');
my $xmldoc = $xmlparser->parse_file('t/xml/test1.xml');
my $html = $tr->transform($xmldoc);
ok($html =~ m{<h1>Result 1</h1>}, "Transforming with test.xsl with new and clear cache");
ok($tr->status == $File::Cache::Persistent::FILE, "Status: initial read");

$xmldoc = $xmlparser->parse_file('t/xml/test2.xml');
$html = $tr->transform($xmldoc);
ok($html =~ m{<h1>Result 1</h1>}, "Cache already contains test.xsl");
ok($tr->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::NOT_MODIFIED, "Status: cached + not modified");

unlink 't/xsl/test.xsl';
cp('t/xsl/test2.xsl', 't/xsl/test.xsl');

$html = $tr->transform($xmldoc);
ok($html =~ m{<h1>Result No 2</h1>}, "test.xsl modified");
ok($tr->status == $File::Cache::Persistent::FILE, "Status: file modified");

$xmldoc = $xmlparser->parse_file('t/xml/test3.xml');
$html = $tr->transform($xmldoc);
ok($html =~ m{<h1>Result No 2</h1>}, "Using test2.xsl (first time)");
ok($tr->status == $File::Cache::Persistent::FILE, "Status: initial read");

unlink 't/xsl/test.xsl';

$html = $tr->transform('t/xml/test2.xml');
ok($html =~ m{<h1>Result No 2</h1>}, "Using deleted test.xsl");
ok($tr->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::NO_FILE, "Status: deleted file");

$html = $tr->transform('t/xml/test3.xml');
ok($html =~ m{<h1>Result No 2</h1>}, "Using test2.xsl again");
ok($tr->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::NOT_MODIFIED, "Status: cache");

$html = $tr->transform(<<XML);
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="t/xsl/test1.xsl"?>
<page>
    <manifest>
        <title>Inline test XML Doc</title>
    </manifest>
    <content>
        <empty/>
    </content>
</page>
XML
ok ($html =~ m{<h1>Result 1</h1>}, "test1.xsl which was never used before");
ok($tr->status == $File::Cache::Persistent::FILE, "Status: initial read");

# Using time cacheing.

my $tr2 = new XSLT::Cache(
    timeout => 2
);

$html = $tr2->transform('t/xml/test4.xml');
ok($html =~ m{<h1>Converted 3</h1>}, "First time test3.xsl (2 sec cache)");
ok($tr2->status == $File::Cache::Persistent::FILE, "Status: initial read");

sleep 3;
$html = $tr2->transform('t/xml/test4.xml');
ok ($html =~ m{<h1>Converted 3</h1>}, "Again test3.xsl (2 sec cache)");
ok($tr2->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::TIME_CACHE + $File::Cache::Persistent::TIMEOUT + $File::Cache::Persistent::NOT_MODIFIED + $File::Cache::Persistent::PROLONG, "Status: timeout + not modified; prolongated");

$html = $tr2->transform('t/xml/test4.xml');
ok($html =~ m{<h1>Converted 3</h1>}, "Once more test3.xsl without the delay (2 sec cache)");
ok($tr2->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::TIME_CACHE, "Status: time cache");


$html = $tr2->transform('t/xml/test5.xml');
ok($html =~ m{<h1>Converted 4</h1>}, "Using test4.xsl for the first time (2 sec cache)");
ok($tr2->status == $File::Cache::Persistent::FILE, "Status: initial read");

$html = $tr2->transform('t/xml/test5.xml');
ok($html =~ m{<h1>Converted 4</h1>}, "Using test4.xsl for the second time (2 sec cache)");
ok($tr2->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::TIME_CACHE, "Status: time cache");

sleep 1;
cp('t/xsl/test4.xsl', 't/xsl/temp.xsl');
unlink 't/xsl/test4.xsl';
cp('t/xsl/temp.xsl', 't/xsl/test4.xsl');
unlink 't/xsl/temp.xsl';

$html = $tr2->transform('t/xml/test5.xml');
ok($html =~ m{<h1>Converted 4</h1>}, "Using test4.xsl after mtime changed less than 2 sec (2 sec cache)");
ok($tr2->status == $File::Cache::Persistent::CACHE + $File::Cache::Persistent::TIME_CACHE, "Status: time cache");

sleep 3;
cp('t/xsl/test4.xsl', 't/xsl/temp.xsl');
unlink 't/xsl/test4.xsl';
cp('t/xsl/temp.xsl', 't/xsl/test4.xsl');
unlink 't/xsl/temp.xsl';

$html = $tr2->transform('t/xml/test5.xml');
ok($html =~ m{<h1>Converted 4</h1>}, "Using test4.xsl after mtime changed more than 2 sec (2 sec cache)");
ok($tr2->status == $File::Cache::Persistent::FILE + $File::Cache::Persistent::TIMEOUT, "Status: timout + file modified");

sub cp {
    my ($patha, $pathb) = @_;

    local $/;
    undef $/;

    open my $filea, '<', $patha;
    my $data = <$filea>;
    close $filea;

    open my $fileb, '>', $pathb;
    print $fileb $data;
    close $fileb;
}
