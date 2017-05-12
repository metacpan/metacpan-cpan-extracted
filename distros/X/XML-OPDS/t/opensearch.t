#!perl

use strict;
use warnings;
use utf8;
use Test::More tests => 5;
use XML::OPDS;
use XML::OPDS::Navigation;
use XML::OPDS::Navigation;
use XML::OPDS::OpenSearch::Query;
use Data::Page;
my $feed = XML::OPDS->new;
$feed->add_to_navigations_new_level(title => 'Search results',
                                    href => '/search');
$feed->add_to_navigations(title => 'Search results',
                          rel => 'start',
                          href => '/opds');

my $query = XML::OPDS::OpenSearch::Query->new(role => "example",
                                              searchTerms => "my terms",
                                              );

$feed->add_to_acquisitions(
                           href => '/second/title',
                           title => 'Second title',
                           files => [ '/second/title.epub' ],
                          );

my $pager = Data::Page->new;
$pager->total_entries(50);
$pager->entries_per_page(20);
$pager->current_page(1);
$feed->search_result_pager($pager);
$feed->search_result_terms('my terms');
$feed->search_result_queries([$query]);
ok($feed);
ok($feed->atom);
my $xml = $feed->render;
like($xml, qr{<opensearch:Query.*role="request".*</opensearch:Query>.*<opensearch:Query.*role="example"}s);
unlike($xml, qr{my terms});
like($xml, qr{my%20terms});
diag $feed->render;
print $feed->render;
