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
  plan skip_all => 'XML::Simple required for testing POX content',
  exit;
}
plan tests => 24;

my $netflix = WWW::Netflix::API->new({
	%env,
	content_filter => sub { XMLin(@_) },
});

sub check_queues {
  my $netflix = shift;
  my $id = shift;
  my $title_ref = shift;
  my ($disc_state, $disc_position, $instant_state, $instant_position) = @_;
  my %info;

  $netflix->REST->Users->Title_States;
  $netflix->Get( title_refs => $title_ref );
  my $items = $netflix->content->{title_state}->{title_state_item};
  $items = [ $items ] unless ref($items) eq 'ARRAY';
  foreach my $item ( @$items ){
    next unless $item->{link}->{title} =~ /^(instant|disc) queue$/;
    my $q = $1;
    my ($s) = map { $_->{label} } grep { $_->{scheme} =~ m#/title_states$# } @{ $item->{format}->{category} };
    $info{$q}->{state} = $s;
  }
  
  $netflix->REST->Users->Queues->Instant;
  $netflix->Get( max_results => 500 );
  foreach ( keys %{ $netflix->content->{queue_item} } ){
    next unless m#/(saved|(?<=available/)\d+)/$id$#;
    $info{instant}->{position} = $1;
  }

  $netflix->REST->Users->Queues->Disc;
  $netflix->Get( max_results => 500 );
  foreach ( keys %{ $netflix->content->{queue_item} } ){
    next unless m#/(saved|(?<=available/)\d+)/$id$#;
    $info{disc}->{position} = $1;
  }
  my $etag = $netflix->content->{etag};

  is( $info{disc}->{state},       $disc_state,       "[$id] disc_state" ); 
  is( $info{disc}->{position},    $disc_position,    "[$id] disc_position" ); 
  is( $info{instant}->{state},    $instant_state,    "[$id] instant_state" ); 
  is( $info{instant}->{position}, $instant_position, "[$id] instant_position" ); 

  return $etag;
}

my $id = '70040478';
$netflix->REST->Catalog->Titles->Discs($id);
my $ref = $netflix->url;
my $dpos = 10;
my $ipos = 20;
my $etag;


# delete from both queues
# check title_state

# clear out from disc queue, if it's there.
$netflix->REST->Users->Queues->Disc->Available($id);
$netflix->Delete;

# clear out from instant queue, if it's there.
$netflix->REST->Users->Queues->Instant->Available($id);
$netflix->Delete;

# check that starting w/clean slate.
$etag = check_queues( $netflix, $id, $ref, 'Add', undef, 'Play', undef );

# add to disc queue
$netflix->REST->Users->Queues->Disc;
ok( $netflix->Post( title_ref => $ref, position => $dpos, etag => $etag ), 'Adding to Disc queue' );
$etag = check_queues( $netflix, $id, $ref, 'In Queue', $dpos, 'Play', undef );

# add to instant queue
$netflix->REST->Users->Queues->Instant;
ok( $netflix->Post( title_ref => $ref, position => $ipos, etag => $etag ), 'Adding to Instant queue' );
$etag = check_queues( $netflix, $id, $ref, 'In Queue', $dpos, 'In Queue', $ipos );

# delete from disc queue
$netflix->REST->Users->Queues->Disc->Available($id);
ok( $netflix->Delete, 'Removing from Disc queue' )
  or diag $netflix->content_error;
$etag = check_queues( $netflix, $id, $ref, 'Add', undef, 'In Queue', $ipos );

# delete from instant queue
$netflix->REST->Users->Queues->Instant->Available($id);
ok( $netflix->Delete, 'Removing from Instant queue' )
  or diag $netflix->content_error;
$etag = check_queues( $netflix, $id, $ref, 'Add', undef, 'Play', undef );


__END__

use Data::Dumper;
print Dumper [ $netflix->content, $netflix->content_error ];
exit;

# instant queue: In Queue
# disc queue: In Queue
# instant queue: Play
# disc queue: Add

use Data::Dumper;
$netflix->REST->Users->Title_States;
$netflix->Get( title_refs => $ref );
print Dumper $netflix->content;

my $items = $netflix->content->{title_state}->{title_state_item};
$items = [ $items ] unless ref($items) eq 'ARRAY';
foreach my $item ( @$items ){
  my $q = $item->{link}->{title};
  my ($s) = map { $_->{label} } grep { $_->{scheme} =~ m#/title_states$# } @{ $item->{format}->{category} };
  print "$q: $s\n";
}
exit;

#$netflix->REST->Users->Queues->Disc->Available($id);
#$netflix->Delete;
#print Dumper $netflix->content;

#exit;

$netflix->REST->Users->Queues->Instant(max_results => 1);
$netflix->Get;
my $etag = $netflix->content->{etag};
warn "ETA: " . $etag;

$netflix->REST->Users->Queues->Instant;
warn $netflix->Post( title_ref => $ref, position => 40, etag => $etag );

print Dumper $netflix->content;

$netflix->REST->Users->Queues->Instant;
$netflix->Get( max_results => 500 );
open FILE, '>out2.txt';
print FILE Dumper $netflix->content;
close FILE;

