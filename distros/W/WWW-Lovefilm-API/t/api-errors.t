#!perl

use strict;
use warnings;
use Test::More;
use WWW::Lovefilm::API;
$|=1;

my %env = map { $_ => $ENV{"WWW_LOVEFILM_API__".uc($_)} } qw/
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
  plan skip_all => 'XML::Simple required for testing POX content',
  exit;
}
plan tests => 6;

my $lovefilm = WWW::Lovefilm::API->new({
	%env,
	content_filter => sub { require XML::Simple; XMLin(@_) },
});

sub check_bad_submit {
  my $lovefilm = shift;
  my $status_line = shift;
  my $options = shift || {};
  my $label = sprintf '[%s] ', join('/', @{ $lovefilm->_levels });
  my $uid = $lovefilm->user_id;
  $label =~ s/$uid/<UID>/g;
  is( $lovefilm->Get(%$options), undef, "$label request failed" );
  like( $lovefilm->content_error, qr/\(${status_line}\)/, "$label status matches" );
  is( $lovefilm->content, undef, "$label blank content" );
}

my $url;

$lovefilm->REST->Catalog->Titles->Movies('NOT.A.VALID.ID');
check_bad_submit( $lovefilm, '__EMPTY_CONTENT__' );

$lovefilm->REST->Users;
is( $lovefilm->_submit('FOO'), undef,                  "[bad method] got undef" );
is( $lovefilm->content_error,  "Unknown method 'FOO'", "[bad method] status matches" );
is( $lovefilm->content,        undef,                  "[bad method] blank content" );

