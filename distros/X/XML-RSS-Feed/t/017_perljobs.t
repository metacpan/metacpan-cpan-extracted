#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 11;

BEGIN {
    use_ok('XML::RSS::Feed');
    use_ok('XML::RSS::Headline::PerlJobs');
}

my $feed = XML::RSS::Feed->new(
    name  => 'perljobs',
    url   => "http://jobs.perl.org/rss/standard.rss",
    hlobj => "XML::RSS::Headline::PerlJobs"
);
isa_ok( $feed, "XML::RSS::Feed" );
ok( $feed->parse( xml(1) ), "Parse Good Perl Jobs XML" );
is( ( $feed->headlines )[0]->headline,
    "Mid-senior level Perl/Mod_Perl Programmer\n"
        . "Links Technology Solutions, Inc. - United States, "
        . "Arizona, Scottsdale\n"
        . "Full time, Hourly employee",
    "Test to make sure headline matches"
);

my $feed_no_details = XML::RSS::Feed->new(
    name  => 'perljobs',
    url   => "http://jobs.perl.org/rss/standard.rss",
    hlobj => "XML::RSS::Headline::PerlJobs"
);
isa_ok( $feed_no_details, "XML::RSS::Feed" );
ok( $feed_no_details->parse( xml(2) ), "Parse Good Perl Jobs XML" );
is( ( $feed_no_details->headlines )[0]->headline,
    "Mid-senior level Perl/Mod_Perl Programmer\n"
        . "Unknown Location\n"
        . "Unknown Hours, Unknown Terms",
    "Test for missing elements"
);

my $feed_name_only = XML::RSS::Feed->new(
    name  => 'perljobs',
    url   => "http://jobs.perl.org/rss/standard.rss",
    hlobj => "XML::RSS::Headline::PerlJobs",
);
isa_ok( $feed_name_only, "XML::RSS::Feed" );
ok( $feed_name_only->parse( xml(3) ), "Parse Good Perl Jobs XML" );
is( ( $feed_name_only->headlines )[0]->headline,
    "Mid-senior level Perl/Mod_Perl Programmer\n"
        . "Links Technology Solutions, Inc. - Unknown Location\n"
        . "Unknown Hours, Unknown Terms",
    "Test for missing elements"
);

sub xml {
    my ($index) = @_;
    $index--;
    return (
        q|<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:perljobs="http://jobs.perl.org/rss/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>
<channel rdf:about="http://jobs.perl.org/">
<title>jobs.perl.org</title>
<link>http://jobs.perl.org/</link>
<description>The Perl Jobs site</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://jobs.perl.org/job/1942" />
 </rdf:Seq>
</items>
</channel>
<item rdf:about="http://jobs.perl.org/job/1942">
<title>Mid-senior level Perl/Mod_Perl Programmer</title>
<link>http://jobs.perl.org/job/1942</link>
<description>Links Technology Solutions, Inc. - United States, Arizona, Scottsdale (2004-11-02)</description>
<perljobs:hours>Full time</perljobs:hours>
<perljobs:location>United States, Arizona, Scottsdale</perljobs:location>
<perljobs:company_name>Links Technology Solutions, Inc.</perljobs:company_name>
<perljobs:employment_terms>Hourly employee</perljobs:employment_terms>
<perljobs:posted_date>2004-11-02</perljobs:posted_date>
</item>
</rdf:RDF>|,
        q|<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:perljobs="http://jobs.perl.org/rss/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>
<channel rdf:about="http://jobs.perl.org/">
<title>jobs.perl.org</title>
<link>http://jobs.perl.org/</link>
<description>The Perl Jobs site</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://jobs.perl.org/job/1942" />
 </rdf:Seq>
</items>
</channel>
<item rdf:about="http://jobs.perl.org/job/1942">
<title>Mid-senior level Perl/Mod_Perl Programmer</title>
<link>http://jobs.perl.org/job/1942</link>
<description>Links Technology Solutions, Inc. - United States, Arizona, Scottsdale (2004-11-02)</description>
</item>
</rdf:RDF>|,
        q|<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns="http://purl.org/rss/1.0/"
 xmlns:perljobs="http://jobs.perl.org/rss/"
 xmlns:taxo="http://purl.org/rss/1.0/modules/taxonomy/"
 xmlns:dc="http://purl.org/dc/elements/1.1/"
 xmlns:syn="http://purl.org/rss/1.0/modules/syndication/"
 xmlns:admin="http://webns.net/mvcb/"
>
<channel rdf:about="http://jobs.perl.org/">
<title>jobs.perl.org</title>
<link>http://jobs.perl.org/</link>
<description>The Perl Jobs site</description>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://jobs.perl.org/job/1942" />
 </rdf:Seq>
</items>
</channel>
<item rdf:about="http://jobs.perl.org/job/1942">
<title>Mid-senior level Perl/Mod_Perl Programmer</title>
<link>http://jobs.perl.org/job/1942</link>
<description>Links Technology Solutions, Inc. - United States, Arizona, Scottsdale (2004-11-02)</description>
<perljobs:company_name>Links Technology Solutions, Inc.</perljobs:company_name>
</item>
</rdf:RDF>|
    )[$index];
}
