#!/usr/bin/perl

use strict;
use warnings;
use WWW::Netflix::API;

my %vars = do('./vars.inc');
my $netflix = WWW::Netflix::API->new({
	consumer_key    => $vars{consumer_key},
	consumer_secret => $vars{consumer_secret},
});

$netflix->ua->add_handler( response_header => sub {
  my($response, $ua, $h) = @_;
  $response->{default_add_content} = 0;
  open OUTPUT, '>', 'catalog.xml' or die $!;
} );
$netflix->ua->add_handler( response_data => sub {
  my($response, $ua, $h, $data) = @_;
  print OUTPUT $data or die $!;
  return 1;
} );
$netflix->ua->add_handler( response_done => sub {
  my($response, $ua, $h) = @_;
  close OUTPUT or die $!;
} );

$netflix->REST->Catalog->Titles->DVD;
$netflix->Get();

