package YAX::Text;

use strict;

use base qw/YAX::Node/;

use Scalar::Util qw/weaken/;
use YAX::Constants qw/TEXT_NODE/;

use overload '""' => \&as_string, fallback => 1;

sub TEXT () { 0 }
sub PRNT () { 1 }

sub new {
    my ( $class, $data ) = @_;
    bless [ $data, undef ], $class;
}

sub type { TEXT_NODE }
sub name { '#text' }
sub data { $_[0][TEXT] = $_[1] if @_ == 2; $_[0][TEXT] }

sub clone {
    my $self = shift;
    return ref( $self )->new( $self->data );
}

sub parent { weaken( $_[0][PRNT] = $_[1] ) if @_ == 2; $_[0][PRNT] }

sub as_string {
    return '' unless defined $_[0][TEXT];
    return '' unless length ($_[0][TEXT]);
    $_[0][TEXT];
}

sub entityfy {
    my $text = shift;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/'/&apos;/g;
    $text =~ s/"/&quot;/g;
    $text;
}

1;
__END__

=head1 NAME

YAX::Text - a DOM text node

=head1 SYNOPSIS

 use YAX::Text;
  
 # construct
 my $text = YAX::Text->new( $string );
  
 # access the parent
 my $prnt = $text->parent;
  
 # access siblings
 my $next = $text->next;
 my $prev = $text->prev;
  
 # acccess the value
 my $data = $text->data;
 $text->data( $new_val );
  
 # cloning
 my $copy = $text->clone();
  
 # misc
 my $name = $text->name;    # '#text'
 my $type = $text->type;    # YAX::Constants::TEXT_NODE
  
 # stringify
 my $xstr = $elmt->as_string;
 my $xstr = "$elmt";

=head1 DESCRIPTION

Text nodes for a YAX DOM tree.

=head1 METHODS

=over 4

=item type

Returns the value of YAX::Constants::TEXT_NODE

=item name

Returns the string '#text'.

=item data
=item data( $new_val )

Returns the text data associated with this node. If called with a
parameter, then sets the data to C<$new_val>.

=item next

Returns the next sibling if any.

=item prev

Returns the previous sibling if any.

=item parent

Returns the parent node if any.

=item clone

Returns a copy of this node

=item as_string

Serialization hook, but does the same as $text->data(). '"" is overloaded.

=back

=head1 SEE ALSO

L<YAX:Node>, L<YAX::Element>, L<YAX::Fragment>, L<YAX::Constants>

=head1 AUTHOR

 Richard Hundt

=head1 LICENSE

This program is free software and may be modified and distributed under
the same terms as Perl itself.


