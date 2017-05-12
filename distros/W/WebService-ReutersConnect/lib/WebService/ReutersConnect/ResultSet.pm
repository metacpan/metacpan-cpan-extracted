package WebService::ReutersConnect::ResultSet;
use Moose;

has 'id' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'num_found' => ( is => 'ro', isa => 'Int', required => 1);
has 'start' => ( is => 'ro', isa => 'Int', required => 1);
has 'size' => ( is => 'ro', isa => 'Int', required => 1);
has 'items' => ( is => 'ro',
                 isa => 'ArrayRef[WebService::ReutersConnect::Item]',
                 required => 1 );

__PACKAGE__->meta->make_immutable();
1;

__END__
=head1 NAME

WebService::ReutersConnect::ResultSet - A Result Set of Items.

=head1 ATTRIBUTES

=head2 id

An optional id. Used when this Set is used as a supplemetal links set of an item.

Usage:

  my @supplemental_sets = @{$item->supplemental_sets()};
  foreach my $set ( @supplemental_sets ){
    print "In this set ".$set->id();
    foreach my $item ( @{$set->items()} ){
       print $item->id();
    }
  }

=head2 num_found

The total number of results

=head2 size

The size of this particular set of results.

=head2 start

The start offset of these results in the entire resultspace

=head2 items

An ArrayRef of L<WebService::ReutersConnect::Item>'s

Usage:

 my @items = @{$this->items()};
 foreach my $item ( @items ){
  ...
 }

=cut
