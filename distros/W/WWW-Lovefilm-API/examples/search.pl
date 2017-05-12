#!/usr/bin/perl

use strict;
use warnings;
use WWW::Lovefilm::API;
use XML::Simple;

my $search_string = $ARGV[0] or die "need search string\n";

my $lovefilm = WWW::Lovefilm::API->new({
    do('vars.inc'),
    content_filter => sub { XMLin(@_) },
});

$lovefilm->REST->catalog->title;
$lovefilm->Get(
    term           => $search_string,
    start_index    => 1, # Mmm, zero does not work, must be 1 based index
    items_per_page => 20,
);

my $data = $lovefilm->content;

printf "%d results:\n", $data->{total_results};

while( my ($url, $row) = each %{$data->{catalog_title}} ){
  printf "%s (%s)\n",
	$row->{title}->{clean},
	$row->{release_date},
  ;
}

