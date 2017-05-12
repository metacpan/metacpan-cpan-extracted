package WebService::ReutersConnect::Item;
use Moose;
use DateTime;
use DateTime::Format::ISO8601;
use Log::Log4perl;
my $LOGGER = Log::Log4perl->get_logger();

use URI::Escape;

## Source reuters
has 'reuters' => ( is => 'ro' , isa => 'WebService::ReutersConnect' , weak_ref => 1 , required => 1);

## Source channel.
has 'channel' => ( is => 'ro', isa => 'WebService::ReutersConnect::Channel', required => 1 , lazy_build => 1  );
has 'channel_alias' => ( is => 'ro', isa => 'Str' , required => 1 );

## Raw mandatory attributes.
has 'id' => ( is => 'ro' , isa => 'Str' , required => 1 );
has 'guid' => ( is => 'ro' , isa => 'Str', required => 1);
has 'version' => ( is => 'ro', isa => 'Str', required => 1);
has 'date_created' => ( is => 'ro',  isa => 'DateTime', required => 1);
has 'media_type' => ( is => 'ro', isa => 'Str', required => 1 );

## Raw optional attributes.
has 'headline' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'slug' => ( is => 'ro', isa => 'Maybe[Str]');
has 'raw_preview_url' => ( is => 'ro', isa => 'Maybe[Str]');
has 'priority' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'fragment' => ( is => 'ro', isa => 'Maybe[Str]' );

## Duration in second for video content.
has 'duration' => ( is => 'ro' , isa => 'Maybe[Int]' );

## The main links if this Item is a NEP (News Event Package).
has 'main_links' => ( is => 'ro', isa => 'ArrayRef[WebService::ReutersConnect::Item]' , default => sub{ []; }, required => 1 );
has 'supplemental_sets' => ( is => 'ro', isa => 'ArrayRef[WebService::ReutersConnect::ResultSet]' , default => sub{ []; }, required => 1);

## Extended calculated attributes.
has 'preview_url' => ( is => 'ro', isa => 'Maybe[Str]' , lazy_build => 1 );



=head1 NAME

WebService::ReutersConnect::Item - A ReutersConnect SNI (Simple News Item).

=head1 PROPERTIES

=head2 channel

Origin L<WebService::ReutersConnect::Channel> of this Item.

=head2 id

Absolute ID of this item and version.

=head2 guid

ID of this item regardless of its version.

=head2 date_created

A L<DateTime>

=head2 slug

=head2 headline

=head2 media_type

=head2 preview_url

In case of an image.

=head2 priority

=head2 duration

In case of a Video. Duration in seconds.

=cut

sub _build_preview_url{
  my ($self) = @_;
  my $raw = $self->raw_preview_url();
  unless( $raw ){ return; }
  return $raw.'?token='.uri_escape_utf8($self->reuters->authToken());
}

sub _build_channel{
  my ($self) = @_;
  $LOGGER->debug("Building channel from ".$self->channel_alias());
  my ($channel) = $self->reuters->channels( { channel => [ $self->channel_alias() ] });
  $LOGGER->debug("Got channel '".$channel->description()."'");
  return $channel;
}


=head2 fetch_richer_me

Convenience method that uses WebService::ReutersConnect::fetch_package tp fetch a richer version
of this object. Dies if $this is not composite.

Usage:

  if( $this->is_composite() ){
    $this->fetch_richer_me();
    ## This now contains richer content (according to ReutersConnect's package method.
  }

=cut

sub fetch_richer_me{
  my ($self) = @_;
  unless( $self->is_composite() ){
    confess("Only a composite Item can be made richer");
  }
  my ($richer) = $self->reuters->fetch_package( $self->channel_alias() , [ $self->id() ]);
  return $richer;
}

=head2 is_composite

Returns true if this item is composite. A composite item is
typically a NEP (News Event Package), or a SNEP (Super News Event Package pointing to other NEPs).

usage:

 if( $this->is_composite() ){
    my ( $rich_version ) = $reuters->fetch_package( $this->channel() , [ $this ] );
 }

=cut

sub is_composite{
  my ($self) = @_;
  return $self->media_type() eq 'C';
}

=head2 from_node

Build a new instance from a XML::LibXML::Node. Internal Use.

=cut

sub from_node{
  my ($class, $node, $reuters, $channel) = @_;


  my $build = { reuters => $reuters };
  unless( $channel ){
    ## Just extract the channel ID and let the _build_channel do its job later.
    $build->{channel_alias} =  $node->findvalue('./channel') || confess("Cannot find channel in node ".$node->toString());
  }else{
    $build->{channel} = $channel;
    $build->{channel_alias} = $channel->alias();
  }

  ## $LOGGER->info("Building Item from ".$node->toString());

  $build->{id} = $node->findvalue('./id');
  $build->{guid} = $node->findvalue('./guid');
  $build->{version} = $node->findvalue('./version');
  $build->{date_created} = DateTime::Format::ISO8601->parse_datetime($node->findvalue('./dateCreated'));
  $build->{slug} = $node->findvalue('./slug') || undef;
  $build->{headline} = $node->findvalue('./headline') || undef;
  $build->{fragment} = $node->findvalue('./fragment') || undef;
  $build->{media_type} = $node->findvalue('./mediaType');
  $build->{priority} = $node->findvalue('./priority');
  $build->{raw_preview_url} = $node->findvalue('./previewUrl') || undef;
  $build->{duration} = $node->findvalue('./duration') || undef;

  my @links = ();
  my @link_nodes = $node->findnodes('./mainLinks/link');
  foreach my $link_node ( @link_nodes ){
    push @links, $class->from_node($link_node, $reuters, $channel);
  }
  $build->{'main_links'} = \@links;

  my @supp_sets = ();
  my @supp_set_nodes = $node->findnodes('./supplementalLinks');
  foreach my $supp_set_node ( @supp_set_nodes ){
    my $id = $supp_set_node->getAttribute('id');
    my @link_nodes = $supp_set_node->findnodes('./link');
    my @links = ();
    foreach my $link_node ( @link_nodes ){
      push @links , $class->from_node($link_node, $reuters, $channel);
    }
    my $n_found = scalar(@links);
    my $set = WebService::ReutersConnect::ResultSet->new({ id => $id,
                                                           items => \@links,
                                                           num_found => $n_found,
                                                           size => $n_found,
                                                           start => 0 });
    push @supp_sets , $set;
  }
  $build->{'supplemental_sets'} = \@supp_sets;

  return $class->new( $build );
}

__PACKAGE__->meta->make_immutable();
1;
