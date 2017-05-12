#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use_ok('XML::RSS::Feed');
    use_ok('XML::RSS::Headline::UsePerlJournals');
}

my $feed = XML::RSS::Feed->new(
    name  => 'useperljournals',
    hlobj => "XML::RSS::Headline::UsePerlJournals",
    url   => "http://use.perl.org/search.pl?tid=&query=&author=&"
        . "op=journals&content_type=rss",
);
isa_ok( $feed, "XML::RSS::Feed" );
ok( $feed->parse( xml(1) ), "Parse Fark XML" );
my $headline = ( $feed->headlines )[0];
is( $headline->headline,
    q|[Ovid] The Real CPAN Limitation|,
    "use Perl; Journal headline matched"
);
is( $headline->url,
    q|http://use.perl.org/~Ovid/journal/21897?from=rss|,
    "use Perl; Journal url matched"
);

sub xml {
    my ($index) = @_;
    $index--;
    return (
        q|<?xml version="1.0" encoding="ISO-8859-1"?>

<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:slash="http://purl.org/rss/1.0/modules/slash/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>

<channel rdf:about="http://use.perl.org/search.pl">
<title>use Perl Journal Search</title>
<link>http://use.perl.org/search.pl</link>
<description>use Perl Journal Search</description>
<dc:language>en-us</dc:language>
<dc:rights>use Perl; is Copyright 1998-2004, Chris Nandor. Stories, comments, journals, and other submissions posted on use Perl; are Copyright their respective owners.</dc:rights>
<dc:date>2004-11-17T19:14:51+00:00</dc:date>
<dc:publisher>pudge</dc:publisher>
<dc:creator>pudge@perl.org</dc:creator>
<dc:subject>Technology</dc:subject>
<syn:updatePeriod>hourly</syn:updatePeriod>
<syn:updateFrequency>1</syn:updateFrequency>
<syn:updateBase>1970-01-01T00:00+00:00</syn:updateBase>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://use.perl.org/~Ovid/journal/21897?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~gabor/journal/21896?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~TeeJay/journal/21895?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~TorgoX/journal/21894?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~spur/journal/21893?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~TorgoX/journal/21892?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~TorgoX/journal/21891?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~TorgoX/journal/21890?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~TorgoX/journal/21889?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~spur/journal/21888?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~ethan/journal/21887?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~petdance/journal/21886?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~rjbs/journal/21885?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~pudge/journal/21884?from=rss" />
  <rdf:li rdf:resource="http://use.perl.org/~chaoticset/journal/21883?from=rss" />
 </rdf:Seq>
</items>
<image rdf:resource="http://use.perl.org/images/topics/useperl.gif" />
</channel>

<image rdf:about="http://use.perl.org/images/topics/useperl.gif">
<title>use Perl Journal Search</title>
<url>http://use.perl.org/images/topics/useperl.gif</url>
<link>http://use.perl.org/search.pl</link>
</image>

<item rdf:about="http://use.perl.org/~Ovid/journal/21897?from=rss">
<title>The Real CPAN Limitation (2004.11.17 12:04)</title>
<link>http://use.perl.org/~Ovid/journal/21897?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~gabor/journal/21896?from=rss">
<title>Business readiness of programming languages (2004.11.17 10:20)</title>
<link>http://use.perl.org/~gabor/journal/21896?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~TeeJay/journal/21895?from=rss">
<title>google for.. uagent stopped msie (2004.11.17  8:36)</title>
<link>http://use.perl.org/~TeeJay/journal/21895?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~TorgoX/journal/21894?from=rss">
<title>Old and/or stuffy (2004.11.17  8:23)</title>
<link>http://use.perl.org/~TorgoX/journal/21894?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~spur/journal/21893?from=rss">
<title>Perl scripting of Scite (2004.11.17  7:17)</title>
<link>http://use.perl.org/~spur/journal/21893?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~TorgoX/journal/21892?from=rss">
<title>Do they have sheep?  Do people marry there? (2004.11.17  6:21)</title>
<link>http://use.perl.org/~TorgoX/journal/21892?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~TorgoX/journal/21891?from=rss">
<title>Cowered in the gloom (2004.11.17  6:19)</title>
<link>http://use.perl.org/~TorgoX/journal/21891?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~TorgoX/journal/21890?from=rss">
<title>15 Pocky, 003525 (2004.11.17  4:48)</title>
<link>http://use.perl.org/~TorgoX/journal/21890?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~TorgoX/journal/21889?from=rss">
<title>At first the signs (2004.11.17  3:50)</title>
<link>http://use.perl.org/~TorgoX/journal/21889?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~spur/journal/21888?from=rss">
<title>regex gotcha in P::RD (2004.11.17  2:00)</title>
<link>http://use.perl.org/~spur/journal/21888?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~ethan/journal/21887?from=rss">
<title>Busy again (2004.11.17  1:38)</title>
<link>http://use.perl.org/~ethan/journal/21887?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~petdance/journal/21886?from=rss">
<title>Mailing list software recommendations, please (2004.11.17  1:33)</title>
<link>http://use.perl.org/~petdance/journal/21886?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~rjbs/journal/21885?from=rss">
<title>gangsters, pirates, databases (2004.11.16 23:31)</title>
<link>http://use.perl.org/~rjbs/journal/21885?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~pudge/journal/21884?from=rss">
<title>New Cool Journal RSS Feeds at use Perl; (2004.11.16 18:32)</title>
<link>http://use.perl.org/~pudge/journal/21884?from=rss</link>
</item>

<item rdf:about="http://use.perl.org/~chaoticset/journal/21883?from=rss">
<title>The Big Meet (2004.11.16 17:13)</title>
<link>http://use.perl.org/~chaoticset/journal/21883?from=rss</link>
</item>

</rdf:RDF>|
    )[$index];
}
