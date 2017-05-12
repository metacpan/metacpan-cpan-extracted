#!perl

use lib 'lib';
use strict;
use warnings;
use WWW::Netflix::API;
use Data::Dumper;
$|=1;

my %env = map { $_ => $ENV{"WWW_NETFLIX_API__".uc($_)} } qw/
        consumer_key
        consumer_secret
/;
use XML::Simple;

my $netflix = WWW::Netflix::API->new({
        %env,
        content_filter => sub { XMLin(@_) },
});
my $base_url = $netflix->{base_url};


$netflix->REST->Catalog->Titles->Movies('517905');
$netflix->Get('expand' => 'cast,directors');

$netflix->REST->Catalog->Titles->Movies('517905')->Cast;
$netflix->Get();

print Dumper $netflix->content;


__END__

my $url = 'http:// . $base_url . '/catalog/titles/movies/517905?expand=cast,directors';
my ($rest, $submit) = $netflix->rest2sugar($url);

print qq{
$url

  $rest;
  $submit;

};

__END__

perl -MWWW::Netflix::API -le 'print for WWW::Netflix::API->new->rest2sugar(shift)' "http://api-public.netflix.com/catalog/titles/movies/517905?expand=cast,directors"


