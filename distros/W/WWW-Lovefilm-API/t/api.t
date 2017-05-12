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
plan tests => 30;

my $lovefilm = WWW::Lovefilm::API->new({
	%env,
	content_filter => sub { XMLin(@_) },
});

sub check_submit {
  my $lovefilm = shift;
  my $keys = shift;
  my $options = shift || {};
  my $label = sprintf '[%s] ', join('/', @{ $lovefilm->_levels });
  my $uid = $lovefilm->user_id;
  $label =~ s/$uid/<UID>/g;
  sleep 1;   # avoid 'Over queries per second limit' error
  ok( $lovefilm->Get(%$options), "$label got data" );
  is( $lovefilm->content_error, undef, "$label no error" );
  is( join(',', sort keys %{$lovefilm->content || {}}), $keys, "$label keys match" );
}


$lovefilm->REST->catalog->title('18704531');
check_submit( $lovefilm, 'average_rating,box_art,category,id,link,release_year,runtime,title' );

$lovefilm->REST->Users;
check_submit( $lovefilm, 'can_instant_watch,first_name,last_name,link,nickname,preferred_formats,user_id' );

$lovefilm->REST->users->at_home;
check_submit( $lovefilm, 'at_home_item,number_of_results,results_per_page,start_index,url_template' );

$lovefilm->REST->Users->Queues;
check_submit( $lovefilm, 'link' );

$lovefilm->REST->Users->Queues->Disc;
check_submit( $lovefilm, 'etag,link,number_of_results,queue_item,results_per_page,start_index,url_template' );

$lovefilm->REST->Users->Queues->Instant;
check_submit( $lovefilm, 'etag,link,number_of_results,queue_item,results_per_page,start_index,url_template' );

$lovefilm->REST('http://openapi.lovefilm.com/catalog/titles/movies/18704531');
check_submit( $lovefilm, 'average_rating,box_art,category,id,link,release_year,runtime,title' );

my $uid = $lovefilm->user_id;
$lovefilm->REST("http://openapi.lovefilm.com/users/$uid/queues/instant");
check_submit( $lovefilm, 'etag,link,number_of_results,queue_item,results_per_page,start_index,url_template' );

