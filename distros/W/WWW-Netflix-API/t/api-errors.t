#!perl

use strict;
use warnings;
use Test::More;
use WWW::Netflix::API;
$|=1;

my %env = map { $_ => $ENV{"WWW_NETFLIX_API__".uc($_)} } qw/
	consumer_key
	consumer_secret
	access_token
	access_secret
	user_id
/;

if( ! $env{consumer_key} ){
  plan skip_all => 'Make sure that ENV vars are set for consumer_key, etc';
  exit;
}
eval "use XML::Simple";
if( $@ ){
  plan skip_all => 'XML::Simple required for testing POX content';
  exit;
}
plan tests => 6;

my $netflix = WWW::Netflix::API->new({
	%env,
	content_filter => sub { require XML::Simple; XMLin(@_) },
});

sub check_bad_submit {
  my $netflix = shift;
  my $status_line = shift;
  my $options = shift || {};
  my $label = sprintf '[%s] ', join('/', @{ $netflix->_levels });
  my $uid = $netflix->user_id;
  $label =~ s/$uid/<UID>/g;
  is( $netflix->Get(%$options), undef, "$label request failed" );
  like( $netflix->content_error, qr/\(${status_line}\)/, "$label status matches" );
  is( $netflix->content, undef, "$label blank content" );
}

my $url;

$netflix->REST->Catalog->Titles->Movies('NOT.A.VALID.ID');
check_bad_submit( $netflix, '__EMPTY_CONTENT__' );

$netflix->REST->Users;
is( $netflix->_submit('FOO'), undef,                  "[bad method] got undef" );
is( $netflix->content_error,  "Unknown method 'FOO'", "[bad method] status matches" );
is( $netflix->content,        undef,                  "[bad method] blank content" );

