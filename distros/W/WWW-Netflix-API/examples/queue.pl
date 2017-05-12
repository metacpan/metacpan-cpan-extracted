#!/usr/bin/perl

use strict;
use warnings;
use WWW::Netflix::API;
use XML::Simple;

my $netflix = WWW::Netflix::API->new({
	do('./vars.inc'),
	content_filter => sub { XMLin(@_) },
});

sub print_queue {
  my $desc = shift;
  my $content = shift;
  foreach my $item (
	sort { $a->{position} <=> $b->{position} }
	grep { $_->{position} }
	values %{$content->{queue_item}}
      ){
    printf "%-7s %-3d %s\n", $desc, $item->{position}, $item->{title}->{regular};
  }
}

$netflix->REST->Users->Queues->Instant;
$netflix->Get(max_results => 500);
print_queue( 'Instant', $netflix->content );

$netflix->REST->Users->Queues->Disc;
$netflix->Get(max_results => 500);
print_queue( 'Disc',    $netflix->content );

