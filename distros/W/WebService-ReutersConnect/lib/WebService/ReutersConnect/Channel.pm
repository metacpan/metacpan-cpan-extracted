package WebService::ReutersConnect::Channel;
use Moose;
use DateTime;
use DateTime::Format::ISO8601;

has 'reuters' => ( is => 'ro', weak_ref => 1 , isa => 'WebService::ReutersConnect', required => 1 );

has 'description' => ( is => 'ro' , isa => 'Str' , default => '' );
has 'alias' => ( is => 'ro' , isa => 'Str' );
has 'last_update' => ( is => 'ro',  isa => 'DateTime' );
has 'categories' => ( is => 'ro', isa => 'ArrayRef[WebService::ReutersConnect::Category]', required => 1,  default => sub{ []; } );

=head1 NAME

WebService::ReutersConnect::Channel - A ReutersConnect Channel

=head2 alias

The 'Primary ID' of the channel.

=head2 description

A short descriptive string.

=head2 last_update

A L<DateTime> of .. the last channel update.

=head2 categories

Retuns an ArrayRef of L<WebService::ReutersConnect::Category>'s

Usage:

  foreach my $cat ( @{$channel->categories()} ){
    print('  Category: '.$cat->id().' - '.$cat->description());
  }

=head2 is_online_report

Returns true if this Channel contains the OLR category.
Online report channel can be used to fetch edited NEPs (News Event Packages)
with the WebService::ReutersConnect::packages method.

Usage:

 if( $this->is_online_report() ){
   ...
 }

=cut

sub is_online_report{
  my ($self) = @_;
  foreach my $cat ( @{$self->categories()} ){
    if( $cat->id() eq 'OLR' ){
      return $cat; ## HIT!
    }
  }
  return; ## Fail.
}

=head2 from_node

Builds a new instance from the given WebService::ReutersConnect and XML node object.

=cut

sub from_node{
  my ($class, $reuters , $node) = @_;

  my $build_params = { reuters => $reuters };

  ## Find description
  my $description = $node->findvalue('./description');
  $build_params->{description} = $description;

  my $alias = $node->findvalue('./alias');
  $build_params->{alias} = $alias;

  my $lastupdate_string = $node->findvalue('./lastUpdate');
  if( $lastupdate_string ){
    $build_params->{'last_update'} = DateTime::Format::ISO8601->parse_datetime($lastupdate_string);
  }

  my @categories = ();
  my @cat_nodes = $node->findnodes('./category');
  foreach my $cat_node ( @cat_nodes ){
    my ( $cat_id , $cat_desc ) = ( $cat_node->getAttribute('id') , $cat_node->getAttribute('description') );
    push @categories , $reuters->_vivify_category({ id => $cat_id , description => $cat_desc });
  }

  $build_params->{'categories'} = \@categories;
  return $class->new($build_params);
}

__PACKAGE__->meta->make_immutable();
1;
