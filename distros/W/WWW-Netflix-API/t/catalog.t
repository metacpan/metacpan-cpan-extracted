#!perl

use strict;
use warnings;
use Test::More;
use WWW::Netflix::API;
$|=1;

my %env = map { $_ => $ENV{"WWW_NETFLIX_API__".uc($_)} } qw/
        consumer_key
        consumer_secret
/;

if( ! $env{consumer_key} ){
  plan skip_all => 'Make sure that ENV vars are set for consumer_key, etc';
  exit;
}
eval "use XML::Simple";
if( $@ ){
  plan skip_all => 'XML::Simple required for testing POX content',
  exit;
}
plan tests => 9;

my $netflix = WWW::Netflix::API->new({
	%env,
	content_filter => sub { XMLin(@_) },
});

is( $netflix->access_token, undef, "no access_token" );
is( $netflix->access_secret, undef, "no access_secret" );
is( $netflix->user_id, undef, "no user_id" );

my $n;


$netflix->REST->Catalog->Titles;
$n = $netflix->Get(
   term        => 'zzyzx',
   start_index => 0,
   max_results => 10,
);
ok( $n, "[catalog/titles] Get succeeded" );
$n = $netflix->content->{number_of_results};
ok( $n, "[catalog/titles] got $n results" );
$n = scalar grep { $_->{title}->{regular} eq 'Zzyzx' } values %{ $netflix->content->{catalog_title} };
ok( $n, "[catalog/titles] found Zzyzx in results" );


$netflix->REST->Catalog->Titles->Autocomplete;
$netflix->Get(
   term        => 'Step',
);
ok( $n, "[catalog/titles/autocomplete] Get succeeded" );
$n = scalar @{ $netflix->content->{autocomplete_item} };
ok( $n, "[catalog/titles/autocomplete] got $n results" );
$n = scalar grep { $_->{title}->{short} eq 'Step Brothers' } @{ $netflix->content->{autocomplete_item} };
ok( $n, "[catalog/titles/autocomplete] found 'Step Brothers' in results" );

