#!/usr/bin/perl

use strict;
use warnings;
use WWW::Netflix::API;
use XML::Simple;

my $search_string = $ARGV[0] or die 'need search string';

my $netflix = WWW::Netflix::API->new({
	do('./vars.inc'),
	content_filter => sub { XMLin(@_) },
});

$netflix->REST->Catalog->Titles;
$netflix->Get(
	term => $search_string,
	start_index => 0,
	max_results => 100,
);

my $data = $netflix->content;

printf "%d results:\n", $data->{number_of_results};

while( my ($url, $row) = each %{$data->{catalog_title}} ){
  printf "%s (%d)\n",
	$row->{title}->{regular},
	$row->{release_year},
  ;
}

