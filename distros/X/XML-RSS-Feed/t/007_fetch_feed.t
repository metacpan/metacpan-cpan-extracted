#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;

BEGIN {
    use_ok('XML::RSS::Feed');
    use_ok('XML::RSS::Headline::PerlJobs');
}

my $feed = XML::RSS::Feed->new(
    name => 'jbisbee_test',
    url  => "http://www.jbisbee.com/rsstest",
);

isa_ok( $feed, 'XML::RSS::Feed' );
ok( $feed->parse( xml(1) ), "Failed to parse XML from " . $feed->url );
cmp_ok( $feed->num_headlines, '==', 10, "Verify correct number of headlines" );
cmp_ok( $feed->late_breaking_news, '==', 10, "Verify mark_all_headlines_read" );
ok( $feed->parse( xml(2) ), "parse XML from " . $feed->url );
cmp_ok( $feed->num_headlines, '>=', 11, "Verify correct number of headlines" );
cmp_ok( $feed->late_breaking_news, '>=', 1, "Verify 1 new story" );

my $seen_feed = XML::RSS::Feed->new(
    name                => 'jbisbee_test',
    url                 => "http://www.jbisbee.com/rsstest",
    init_headlines_seen => 1,
);

isa_ok( $seen_feed, 'XML::RSS::Feed' );
ok( $seen_feed->parse( xml(1) ), "Failed to parse XML from " . $seen_feed->url );
cmp_ok( $seen_feed->num_headlines, '==', 10, "Verify correct number of headlines" );
cmp_ok( $seen_feed->late_breaking_news, '==', 0, "Verify mark_all_headlines_read" );

my $pj_feed = XML::RSS::Feed->new(
    name  => 'perljobs',
    url   => "http://jobs.perl.org/rss/standard.rss",
    hlobj => "XML::RSS::Headline::PerlJobs",
);
isa_ok( $pj_feed, 'XML::RSS::Feed' );
ok( $pj_feed->parse( xml(3) ), "parse XML from " . $pj_feed->url );

sub xml {
    my ($index) = @_;
    $index--;
    return (
        q|<?xml version="1.0"?>
<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns="http://my.netscape.com/rdf/simple/0.9/">

<channel>
<title>jbisbee.com</title>
<link>http://www.jbisbee.com/</link>
<description>Testing XML::RSS::Feed</description>
</channel>

<item>
<title>Wednesday 03rd of November 2004 08:48:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540080</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:47:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540050</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:47:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540020</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:46:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539990</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:46:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539960</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:45:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539930</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:45:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539900</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:44:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539870</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:44:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539840</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:43:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539810</link>
</item>
 

</rdf:RDF>|,
        q|<?xml version="1.0"?>
<rdf:RDF
xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns="http://my.netscape.com/rdf/simple/0.9/">

<channel>
<title>jbisbee.com</title>
<link>http://www.jbisbee.com/</link>
<description>Testing XML::RSS::Feed</description>
</channel>

<item>
<title>Wednesday 03rd of November 2004 08:48:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540110</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:48:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540080</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:47:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540050</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:47:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099540020</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:46:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539990</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:46:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539960</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:45:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539930</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:45:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539900</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:44:30 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539870</link>
</item>
<item>
<title>Wednesday 03rd of November 2004 08:44:00 PM</title>
<link>http://www.jbisbee.com/xml-rss-feed/test/1099539840</link>
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
<dc:language>en-us</dc:language>
<dc:rights>Copyright 2001, jobs.perl.org</dc:rights>
<dc:date>2004-11-03T19:53:09Z</dc:date>
<dc:publisher>ask@perl.org</dc:publisher>
<dc:creator>ask@perl.org</dc:creator>
<dc:subject>Perl Jobs</dc:subject>
<syn:updatePeriod>daily</syn:updatePeriod>
<syn:updateFrequency>8</syn:updateFrequency>
<syn:updateBase>1901-01-01T00:00+00:00</syn:updateBase>
<items>
 <rdf:Seq>
  <rdf:li rdf:resource="http://jobs.perl.org/job/1694" />
  <rdf:li rdf:resource="http://jobs.perl.org/job/1944" />
  <rdf:li rdf:resource="http://jobs.perl.org/job/1943" />
  <rdf:li rdf:resource="http://jobs.perl.org/job/1942" />
  <rdf:li rdf:resource="http://jobs.perl.org/job/1941" />
  <rdf:li rdf:resource="http://jobs.perl.org/job/1940" />
  <rdf:li rdf:resource="http://jobs.perl.org/job/1939" />
  <rdf:li rdf:resource="http://jobs.perl.org/job/1938" />
  <rdf:li rdf:resource="http://jobs.perl.org/job/1937" />
  <rdf:li rdf:resource="http://jobs.perl.org/job/1935" />
  <rdf:li rdf:resource="http://jobs.perl.org/job/1934" />
  <rdf:li rdf:resource="http://jobs.perl.org/job/1849" />
 </rdf:Seq>
</items>
</channel>

<item rdf:about="http://jobs.perl.org/job/1694">
<title>Sr Perl Database Developer with Perl, Unix and Oracle; not a DBA</title>
<link>http://jobs.perl.org/job/1694</link>
<description>eQuest Solutions - CA, Pasadena (2004-11-03)</description>
<perljobs:hours>Full time</perljobs:hours>
<perljobs:location>CA, Pasadena</perljobs:location>
<perljobs:company_name>eQuest Solutions</perljobs:company_name>
<perljobs:employment_terms>Salaried employee</perljobs:employment_terms>
<perljobs:posted_date>2004-11-03</perljobs:posted_date>
</item>

<item rdf:about="http://jobs.perl.org/job/1944">
<title>Perl/mod_perl/mysql/apache developer</title>
<link>http://jobs.perl.org/job/1944</link>
<description>Coreware Ltd - United Kingdom, Surrey, Guildford (2004-11-03)</description>
<perljobs:hours>Full time</perljobs:hours>
<perljobs:location>United Kingdom, Surrey, Guildford</perljobs:location>
<perljobs:company_name>Coreware Ltd</perljobs:company_name>
<perljobs:employment_terms>Salaried employee</perljobs:employment_terms>
<perljobs:posted_date>2004-11-03</perljobs:posted_date>
</item>

<item rdf:about="http://jobs.perl.org/job/1943">
<title>Sr Perl Developer of Reporting/BI systems</title>
<link>http://jobs.perl.org/job/1943</link>
<description>eQuest Solutions - United States, CA, West LA (2004-11-02)</description>
<perljobs:hours>Full time</perljobs:hours>
<perljobs:location>United States, CA, West LA</perljobs:location>
<perljobs:company_name>eQuest Solutions</perljobs:company_name>
<perljobs:employment_terms>Salaried employee</perljobs:employment_terms>
<perljobs:posted_date>2004-11-02</perljobs:posted_date>
</item>

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

<item rdf:about="http://jobs.perl.org/job/1941">
<title>Senior Perl Developer</title>
<link>http://jobs.perl.org/job/1941</link>
<description>Performics, Inc. - United States, IL, Chicago (2004-11-02)</description>
<perljobs:hours>Full time</perljobs:hours>
<perljobs:location>United States, IL, Chicago</perljobs:location>
<perljobs:company_name>Performics, Inc.</perljobs:company_name>
<perljobs:employment_terms>Salaried employee</perljobs:employment_terms>
<perljobs:posted_date>2004-11-02</perljobs:posted_date>
</item>

<item rdf:about="http://jobs.perl.org/job/1940">
<title>Software Engineer</title>
<link>http://jobs.perl.org/job/1940</link>
<description>Where2GetIt, Inc. - United States, Illinois, Wheeling (2004-11-02)</description>
<perljobs:hours>Full time</perljobs:hours>
<perljobs:location>United States, Illinois, Wheeling</perljobs:location>
<perljobs:company_name>Where2GetIt, Inc.</perljobs:company_name>
<perljobs:employment_terms>Salaried employee</perljobs:employment_terms>
<perljobs:posted_date>2004-11-02</perljobs:posted_date>
</item>

<item rdf:about="http://jobs.perl.org/job/1939">
<title>Perl/CGI/Apache/FTP Programmer</title>
<link>http://jobs.perl.org/job/1939</link>
<description>AAA Microcomputer Service - United States, CA, Long Beach (2004-11-01)</description>
<perljobs:hours>Flexible</perljobs:hours>
<perljobs:location>United States, CA, Long Beach</perljobs:location>
<perljobs:company_name>AAA Microcomputer Service</perljobs:company_name>
<perljobs:employment_terms>Independent contractor (project-based)</perljobs:employment_terms>
<perljobs:posted_date>2004-11-01</perljobs:posted_date>
</item>

<item rdf:about="http://jobs.perl.org/job/1938">
<title>Super-sweet hackers looking to make the world a better place</title>
<link>http://jobs.perl.org/job/1938</link>
<description>athenahealth - United States, MA, Boston (Waltham) (2004-11-01)</description>
<perljobs:hours>Full time</perljobs:hours>
<perljobs:location>United States, MA, Boston (Waltham)</perljobs:location>
<perljobs:company_name>athenahealth</perljobs:company_name>
<perljobs:employment_terms>Salaried employee</perljobs:employment_terms>
<perljobs:posted_date>2004-11-01</perljobs:posted_date>
</item>

<item rdf:about="http://jobs.perl.org/job/1937">
<title>Perl/CGI/DBI/MySQL/Apache/modperl Programmer for Intnl Software Company</title>
<link>http://jobs.perl.org/job/1937</link>
<description>CyberSurfers Inc. / Annuk Inc. - India, Punjab, Haryana, Delhi, Chandigarh (2004-11-01)</description>
<perljobs:hours>Full time</perljobs:hours>
<perljobs:location>India, Punjab, Haryana, Delhi, Chandigarh</perljobs:location>
<perljobs:company_name>CyberSurfers Inc. / Annuk Inc.</perljobs:company_name>
<perljobs:employment_terms>Salaried employee</perljobs:employment_terms>
<perljobs:posted_date>2004-11-01</perljobs:posted_date>
</item>

<item rdf:about="http://jobs.perl.org/job/1935">
<title>Need CSS look &amp; feel, UI overhaul for Perl/Mason site</title>
<link>http://jobs.perl.org/job/1935</link>
<description>Prop erty Res earch Part ners LLC - United States, NY, New York City (2004-10-30)</description>
<perljobs:hours>Full time</perljobs:hours>
<perljobs:location>United States, NY, New York City</perljobs:location>
<perljobs:company_name>Prop erty Res earch Part ners LLC</perljobs:company_name>
<perljobs:employment_terms>Independent contractor (hourly)</perljobs:employment_terms>
<perljobs:posted_date>2004-10-30</perljobs:posted_date>
</item>

<item rdf:about="http://jobs.perl.org/job/1934">
<title>Sysadmin/Syscoder Dream Job -- Purely Remote</title>
<link>http://jobs.perl.org/job/1934</link>
<description>Telerama - United States, PA, Pittsburgh (2004-10-29)</description>
<perljobs:hours>Full time</perljobs:hours>
<perljobs:location>United States, PA, Pittsburgh</perljobs:location>
<perljobs:company_name>Telerama</perljobs:company_name>
<perljobs:employment_terms>Salaried employee</perljobs:employment_terms>
<perljobs:posted_date>2004-10-29</perljobs:posted_date>
</item>

<item rdf:about="http://jobs.perl.org/job/1849">
<title>WEB DEVELOPER/PROGRAMMER NEEDED</title>
<link>http://jobs.perl.org/job/1849</link>
<description>eSiteGuru.com - United States, CA, Roseville (2004-10-28)</description>
<perljobs:hours>Full time</perljobs:hours>
<perljobs:location>United States, CA, Roseville</perljobs:location>
<perljobs:company_name>eSiteGuru.com</perljobs:company_name>
<perljobs:employment_terms>Salaried employee</perljobs:employment_terms>
<perljobs:posted_date>2004-10-28</perljobs:posted_date>
</item>

</rdf:RDF>|

    )[$index];
}
