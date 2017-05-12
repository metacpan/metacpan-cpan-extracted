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

if( ! ($env{consumer_key} && $env{consumer_secret} && $env{access_token} && $env{access_secret} && $env{user_id} )){
  plan skip_all => 'Make sure that ENV vars are set for consumer_key, etc';
  exit;
}
eval "use XML::Simple";
if( $@ ){
  plan skip_all => 'XML::Simple required for testing POX content',
  exit;
}
plan tests => 24;

my $lovefilm = WWW::Lovefilm::API->new({
	%env,
	content_filter => sub { XMLin(@_) },
});

sub check_queues {
  my $lovefilm = shift;
  my $id = shift;
  my $title_ref = shift;
  my ($disc_state, $disc_position, $instant_state, $instant_position) = @_;
  my %info;

  $lovefilm->REST->Users->Title_States;
  $lovefilm->Get( title_refs => $title_ref );
  my $items = $lovefilm->content->{title_state}->{title_state_item};
  $items = [ $items ] unless ref($items) eq 'ARRAY';
  foreach my $item ( @$items ){
    next unless $item->{link}->{title} =~ /^(instant|disc) queue$/;
    my $q = $1;
    my ($s) = map { $_->{label} } grep { $_->{scheme} =~ m#/title_states$# } @{ $item->{format}->{category} };
    $info{$q}->{state} = $s;
  }
  
  $lovefilm->REST->Users->Queues->Instant;
  $lovefilm->Get( max_results => 500 );
  foreach ( keys %{ $lovefilm->content->{queue_item} } ){
    next unless m#/(saved|(?<=available/)\d+)/$id$#;
    $info{instant}->{position} = $1;
  }

  $lovefilm->REST->Users->Queues->Disc;
  $lovefilm->Get( max_results => 500 );
  foreach ( keys %{ $lovefilm->content->{queue_item} } ){
    next unless m#/(saved|(?<=available/)\d+)/$id$#;
    $info{disc}->{position} = $1;
  }
  my $etag = $lovefilm->content->{etag};

  is( $info{disc}->{state},       $disc_state,       "[$id] disc_state" ); 
  is( $info{disc}->{position},    $disc_position,    "[$id] disc_position" ); 
  is( $info{instant}->{state},    $instant_state,    "[$id] instant_state" ); 
  is( $info{instant}->{position}, $instant_position, "[$id] instant_position" ); 

  return $etag;
}

my $id = '70040478';
$lovefilm->REST->Catalog->Titles->Discs($id);
my $ref = $lovefilm->url;
my $dpos = 10;
my $ipos = 20;
my $etag;


# delete from both queues
# check title_state

# clear out from disc queue, if it's there.
$lovefilm->REST->Users->Queues->Disc->Available($id);
$lovefilm->Delete;

# clear out from instant queue, if it's there.
$lovefilm->REST->Users->Queues->Instant->Available($id);
$lovefilm->Delete;

# check that starting w/clean slate.
$etag = check_queues( $lovefilm, $id, $ref, 'Add', undef, 'Play', undef );

# add to disc queue
$lovefilm->REST->Users->Queues->Disc;
ok( $lovefilm->Post( title_ref => $ref, position => $dpos, etag => $etag ), 'Adding to Disc queue' );
$etag = check_queues( $lovefilm, $id, $ref, 'In Queue', $dpos, 'Play', undef );

# add to instant queue
$lovefilm->REST->Users->Queues->Instant;
ok( $lovefilm->Post( title_ref => $ref, position => $ipos, etag => $etag ), 'Adding to Instant queue' );
$etag = check_queues( $lovefilm, $id, $ref, 'In Queue', $dpos, 'In Queue', $ipos );

# delete from disc queue
$lovefilm->REST->Users->Queues->Disc->Available($id);
ok( $lovefilm->Delete, 'Removing from Disc queue' )
  or diag $lovefilm->content_error;
$etag = check_queues( $lovefilm, $id, $ref, 'Add', undef, 'In Queue', $ipos );

# delete from instant queue
$lovefilm->REST->Users->Queues->Instant->Available($id);
ok( $lovefilm->Delete, 'Removing from Instant queue' )
  or diag $lovefilm->content_error;
$etag = check_queues( $lovefilm, $id, $ref, 'Add', undef, 'Play', undef );

