#!/usr/bin/perl

use strict;
use warnings;
use WWW::Netflix::API;
use XML::Simple;

my $netflix = WWW::Netflix::API->new({
	do('./vars.inc'),
	content_filter => sub { XMLin(@_) },
});
use Data::Dump qw(dump);
warn dump $netflix;

$netflix->REST->Users->Feeds;
$netflix->Get();

my $links = $netflix->content->{link};
foreach my $link ( @$links ){
  next unless $link->{rel} =~ m#/feed\.(.+)#;
  my $f = $1;
  $f =~ s/\./-/g;
  $f .= ".rss";

warn "$f ".`date`;

  $netflix->content_filter(undef);
  $netflix->REST( $link->{href} );
  $netflix->Get( max_results => 500 );
  open FILE, '>', $f;
  print FILE $netflix->content;
  close FILE;

# Alternative method:
#    use LWP::Simple;
#    getstore( $link->{href} .'&max_results=500', $f );

}

