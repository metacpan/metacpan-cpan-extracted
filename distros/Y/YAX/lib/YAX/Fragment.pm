package YAX::Fragment;

use strict;

use YAX::Constants qw/DOCUMENT_FRAGMENT_NODE/;

use base qw/YAX::Element/;

sub new {
    my $class = shift;
    my $self = bless \[ '#fragment', { }, [ @_ ] ], $class;
    $self;
}

sub type { DOCUMENT_FRAGMENT_NODE() }
sub name { '#fragment' }

sub as_string {
    my $self = shift;
    return $self->children_as_string();
}

sub attributes_as_string { '' }

1;

__END__

=head1 NAME

YAX::Fragment - YAX document fragment node

=head1 SYNOPSIS

 use YAX::Fragment;
 $frag = YAX::Fragment->new( @kids );

 # append all the children of $frag to $elmt
 $elmt->append( $frag )

=head1 DESCRIPTION

This module implements document fragment nodes for YAX. These are
useful for manipulating the DOM with sets of nodes. When a fragment
is appended to an element node, only its children become part of
the DOM tree, the fragment itself is discarded.

All DOM mutation operations which take an element as a parameter can
take a fragment as well (so C<replace(...)> and C<insert(...)> work
too). YAX::Fragment inherits from L<YAX::Element>.

=head1 SEE ALSO

L<YAX::Element>

=head1 AUTHOR

 Richard Hundt

=head1 LICENSE

This program is free software and may be modified and distributed under
the same terms as Perl itself.
