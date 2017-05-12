use strict;
use warnings;

use Test::More tests => 31;    # last test to print
use WWW::Ohloh::API;
use XML::LibXML;

require 't/FakeOhloh.pm';

my $ohloh = Fake::Ohloh->new;

$ohloh->stash( 'project',  'project.xml' );
$ohloh->stash( 'factoids', 'factoids.xml' );

my $p = $ohloh->get_project(10716);

like $p->as_xml => qr#<project>.*</project>#s, 'as_xml';

is $p->id            => 10716,                  'id';
is $p->name          => 'WWW::Ohloh::API',      'name';
is $p->created_at    => '2008-01-03T20:55:40Z', 'created_at';
is $p->updated_at    => '2008-01-03T21:20:21Z', 'updated at';
like $p->description => qr/A Perl interface/,   'description';
is $p->homepage_url =>
  'http://search.cpan.org/search%3fmodule=WWW::Ohloh::API',
  'homepage';
is $p->download_url =>
  'http://search.cpan.org/search%3fmodule=WWW::Ohloh::API',
  'download';
is $p->irc_url            => '',     'irc';
is $p->stack_count        => 1,      'stack count';
is $p->average_rating + 0 => 0,      'average rating';
is $p->rating_count       => 0,      'rating count';
is $p->analysis_id        => 100430, 'analysis id';

my $a = $p->analysis;

is $a->id => 100430, "analysis id";
is $a->project_id => $p->id, "analysis project id";
is $a->updated_at => '2008-01-03T21:20:21Z', "analysis updated_at";
is $a->logged_at  => '2008-01-03T20:59:39Z', "analysis logged_at";
is $a->min_month  => '2008-01-01T00:00:00Z', "analysis min_month";
is $a->max_month  => '2008-01-01T00:00:00Z', "analysis max_month";
is $a->twelve_month_contributor_count => 1,      "analysis 12_month_cont";
is $a->total_code_lines               => 381,    "analysis code lines";
is $a->main_language_id               => 8,      'analysis main lang id';
is $a->main_language_name             => 'Perl', 'analysis main lang name';
is $a->main_language                  => 'Perl', 'analysis main lang';
is $a->language                       => 'Perl', 'analysis lang';

my @factoids = $p->factoids;

$p->factoids;
ok 1, "no reload";

is scalar(@factoids) => 4, 'factoids()';

isa_ok $_ => 'WWW::Ohloh::API::Factoid', 'factoid' for @factoids;

