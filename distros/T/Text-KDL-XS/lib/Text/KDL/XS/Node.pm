package Text::KDL::XS::Node;

use strict;
use warnings;

# A Node is a hashref:
#   name            : string
#   type_annotation : string|undef
#   args            : arrayref of Text::KDL::XS::Value
#   props           : arrayref of [name => Text::KDL::XS::Value]   (ordered)
#   prop_index      : { name => idx_into_props }                   (last-wins)
#   children        : arrayref of Text::KDL::XS::Node
sub new {
    my ($class, %args) = @_;
    return bless {
        name            => $args{name},
        type_annotation => $args{type_annotation},
        args            => $args{args}     // [],
        props           => $args{props}    // [],
        prop_index      => $args{prop_index} // {},
        children        => $args{children} // [],
    }, $class;
}

sub name            { $_[0]->{name}            }
sub type_annotation { $_[0]->{type_annotation} }
sub args            { $_[0]->{args}            }
sub props           { $_[0]->{props}           }
sub children        { $_[0]->{children}        }

sub prop {
    my ($self, $key) = @_;
    my $idx = $self->{prop_index}{$key};
    return undef unless defined $idx;
    return $self->{props}[$idx][1];
}

# Plain Perl view - lossy with respect to property order and per-arg type
# annotations. Documented in POD.
sub as_data {
    my ($self) = @_;
    return {
        name     => $self->{name},
        type     => $self->{type_annotation},
        args     => [ map { $_->as_perl } @{ $self->{args} } ],
        props    => { map { $_->[0] => $_->[1]->as_perl } @{ $self->{props} } },
        children => [ map { $_->as_data } @{ $self->{children} } ],
    };
}

# Internal: append (used by the tree builder)
sub _push_arg {
    my ($self, $value) = @_;
    push @{ $self->{args} }, $value;
}

sub _push_prop {
    my ($self, $key, $value) = @_;
    push @{ $self->{props} }, [ $key, $value ];
    $self->{prop_index}{$key} = $#{ $self->{props} };
}

sub _push_child {
    my ($self, $child) = @_;
    push @{ $self->{children} }, $child;
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::KDL::XS::Node - A KDL node (name + args + props + children)

=head1 METHODS

=over 4

=item C<name>            - the node identifier (string)

=item C<type_annotation> - KDL type tag (e.g. C<author>) or C<undef>

=item C<args>            - arrayref of L<Text::KDL::XS::Value> objects

=item C<props>           - ordered arrayref of C<[ key =E<gt> Value ]> pairs

=item C<prop($key)>      - Value for a given property name (last-wins)

=item C<children>        - arrayref of child Nodes

=item C<as_data>

A lossy plain-Perl view of the node tree:

  {
      name     => $string,
      type     => $string_or_undef,
      args     => [ $perl_scalar, ... ],
      props    => { $key => $perl_scalar, ... },  # last-wins
      children => [ \%child_node, ... ],
  }

Property ordering and per-value type annotations are dropped; for
fidelity, walk the blessed tree directly.

=back

=cut
