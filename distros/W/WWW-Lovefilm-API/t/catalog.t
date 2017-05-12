#!perl

use strict;
use warnings;
use Test::More;
use WWW::Lovefilm::API;
$|=1;

my %env = map { $_ => $ENV{"WWW_LOVEFILM_API__".uc($_)} } qw/
        consumer_key
        consumer_secret
/;

if( ! $env{consumer_key} && ! $env{consumer_secret}){
  plan skip_all => 'Make sure that ENV vars are set for consumer_key & consumer_secret';
  exit;
}
eval "use XML::Simple";
if( $@ ){
  plan skip_all => 'XML::Simple required for testing POX content',
  exit;
}
plan tests => 6;

my $lovefilm = WWW::Lovefilm::API->new({
	%env,
	content_filter => sub { XMLin(@_) },
});

is( $lovefilm->access_token, undef, "no access_token" );
is( $lovefilm->access_secret, undef, "no access_secret" );
is( $lovefilm->user_id, undef, "no user_id" );

my $n;


$lovefilm->REST->Catalog->Title;
$n = $lovefilm->Get(
   term        => 'zzyzx',
);
ok( $n, "[catalog/title] Get succeeded" );

$n = $lovefilm->content->{total_results};
ok( $n, "[catalog/title] got $n results" );

my $clean = $lovefilm->content->{catalog_title}->{title}->{clean};
ok( $clean eq 'Zzyzx', "clean name is Zzyzx" ) or diag("clean = $clean");



