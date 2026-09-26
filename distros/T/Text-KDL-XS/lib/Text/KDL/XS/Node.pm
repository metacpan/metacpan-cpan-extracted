package Text::KDL::XS::Node;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use Text::KDL::XS ();

our @CARP_NOT = qw(
    Text::KDL::XS Text::KDL::XS::Document Text::KDL::XS::Emitter
    Text::KDL::XS::Parser Text::KDL::XS::Value
);

my %IS_FIELD = map { $_ => 1 } qw(name type_annotation args props children);

sub new {
    my ($class, @fields) = @_;
    my $fields = Text::KDL::XS::_parse_named_arguments(__PACKAGE__ . '->new', 'field', \%IS_FIELD, @fields);

    Carp::croak(__PACKAGE__ . "->new: 'name' is required") unless defined $fields->{name};
    for my $list (qw(args props children)) {
        next unless defined $fields->{$list};
        Carp::croak(__PACKAGE__ . "->new: '$list' must be an ARRAY reference")
            unless (Scalar::Util::reftype($fields->{$list}) // '') eq 'ARRAY';
    }

    return bless {
        name            => $fields->{name},
        type_annotation => $fields->{type_annotation},
        args            => $fields->{args}     // [],
        props           => $fields->{props}    // [],
        children        => $fields->{children} // [],
    }, $class;
}

# The constructor used by the tree builder, which only ever passes a name and
# an optional type annotation that the parser has already validated.
sub _new_parsed {
    my ($class, $name, $type_annotation) = @_;
    return bless {
        name            => $name,
        type_annotation => $type_annotation,
        args            => [],
        props           => [],
        children        => [],
    }, $class;
}

sub name            { $_[0]->{name}            }
sub type_annotation { $_[0]->{type_annotation} }
sub args            { $_[0]->{args}            }
sub props           { $_[0]->{props}           }
sub children        { $_[0]->{children}        }

# The value of the rightmost property named $key, as the KDL specification
# requires for repeated keys.
sub prop {
    my ($self, $key) = @_;
    Carp::croak(__PACKAGE__ . "::prop: key is required") unless defined $key;
    for my $property (reverse @{ $self->{props} }) {
        return $property->[1] if $property->[0] eq $key;
    }
    return undef;
}

sub as_data {
    my ($self) = @_;
    no warnings 'recursion';    # the parser's max_depth bounds the nesting
    return {
        name     => $self->{name},
        type     => $self->{type_annotation},
        args     => [ map { _perl_value($_) } @{ $self->{args} } ],
        props    => { map { $_->[0] => _perl_value($_->[1]) } @{ $self->{props} } },
        children => [ map { $_->as_data } @{ $self->{children} } ],
    };
}

# Value objects become their natural Perl scalar; plain scalars in hand-built
# nodes are already one.
sub _perl_value {
    my ($value) = @_;
    return Scalar::Util::blessed($value) && $value->isa('Text::KDL::XS::Value') ? $value->as_perl : $value;
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::KDL::XS::Node - A KDL node: name, type annotation, arguments, properties, children

=head1 SYNOPSIS

=for highlighter language=Perl

  # From a parsed document:
  my $node = $doc->nodes->[0];

  $node->name;                    # 'server'
  $node->type_annotation;         # 'primary' for (primary)server, else undef
  $node->args;                    # [ Text::KDL::XS::Value, ... ]
  $node->props;                   # [ [ 'port', Text::KDL::XS::Value ], ... ]
  $node->prop('port');            # Text::KDL::XS::Value or undef
  $node->children;                # [ Text::KDL::XS::Node, ... ]
  $node->as_data;                 # plain hash, see below

  # Built by hand:
  my $node = Text::KDL::XS::Node->new(
      name            => 'server',
      type_annotation => 'primary',                       # optional
      args            => [ Text::KDL::XS::Value->new(type => 'string', value => 'web-1') ],
      props           => [ [ port => Text::KDL::XS::Value->new(type => 'number', kind => 'integer', value => 8080) ] ],
      children        => [ Text::KDL::XS::Node->new(name => 'tls') ],
  );

=for highlighter

=head1 DESCRIPTION

Each KDL node

=for highlighter language=KDL

  (type)name arg1 arg2 key=value {
      child
  }

=for highlighter

is represented by one C<Text::KDL::XS::Node>. The object is a blessed hash
whose contents you may read and modify directly; the accessors below are
the supported way to do so, but pushing onto C<< @{ $node->args } >> or
assigning to C<< $node->{name} >> works and is used in the examples of
L<Text::KDL::XS::Cookbook>.

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=Perl

  my $node = Text::KDL::XS::Node->new(name => $name, %fields);

=for highlighter

Fields (all optional except C<name>, which must be defined):

=over 4

=item name

The node name, a string. Any string is allowed; it is quoted on output if
necessary.

=item type_annotation

The node's C<(type)> annotation as a string, or C<undef> (the default) for
none.

=item args

Array reference of argument values, in order. Elements are normally
L<Text::KDL::XS::Value> objects. Plain scalars, C<undef> and the objects
listed under L<Text::KDL::XS/"Scalar coercion"> are accepted as well and
are converted by L<Text::KDL::XS/emit_kdl> when the node is emitted;
L</as_data> returns them as they are. The C<Value> methods are of course
not available for such elements.

=item props

Array reference of C<[ $key, $value ]> pairs, in order. The same rules for
C<$value> apply as for C<args>.

=item children

Array reference of child C<Text::KDL::XS::Node> objects.

=back

The array references are stored, not copied. A missing or undefined
C<name>, an C<args>, C<props> or C<children> value that is not an array
reference, any other field and an odd number of arguments die, for example
with C<Text::KDL::XS::Node-E<gt>new: 'name' is required>. C<new> may be
called on a subclass.

=head1 METHODS

=head2 name

The node name as a character string. Never C<undef> for a parsed node.

=head2 type_annotation

The C<(type)> written before the node name, or C<undef> if there is none.

=head2 args

Array reference of the node's arguments as L<Text::KDL::XS::Value>
objects, in document order. Empty array reference when there are none.

=for highlighter language=Perl

  my @strings = map { $_->as_string } @{ $node->args };
  my $first   = $node->args->[0];      # undef if there are no arguments

=for highlighter

=head2 props

Array reference of C<[ $key, $value ]> pairs in document order, one pair
per property as written, including repeated keys. C<$value> is a
L<Text::KDL::XS::Value>.

=for highlighter language=Perl

  for my $pair (@{ $node->props }) {
      my ($key, $value) = @$pair;
      ...
  }

=for highlighter

=head2 prop

=for highlighter language=Perl

  my $value = $node->prop($key);   # Text::KDL::XS::Value, or undef if absent

=for highlighter

Looks up a property by key. When the key appears more than once the last
occurrence is returned, as the KDL specification requires. Returns C<undef>
for a missing key; a property whose value is C<#null> returns a C<Value>
object with C<is_null> true, so the two cases can be told apart. C<undef>
as the key dies.

C<prop> searches the C<props> array from the end, so it always reflects
its current contents: on hand-built nodes, and after properties have been
added, removed or reordered. The search is linear in the number of
properties, which is small in practice; build a hash from C<props> when a
node has very many.

=head2 children

Array reference of child nodes, in document order. Empty when the node has
no children block (or an empty one).

=head2 as_data

=for highlighter language=Perl

  my $data = $node->as_data;

=for highlighter

Returns the node and its subtree as plain Perl data:

=for highlighter language=Perl

  {
      name     => $string,
      type     => $string_or_undef,             # node type annotation
      args     => [ $scalar, ... ],             # Value->as_perl for each argument
      props    => { $key => $scalar, ... },     # last value wins for repeated keys
      children => [ \%child, ... ],             # same shape, recursively
  }

=for highlighter

Values are converted with L<Text::KDL::XS::Value/as_perl>: C<undef> for
null, C<1>/C<0> for booleans, numbers as numbers (or digit strings for
arbitrary precision values), strings as strings. Plain scalars in
hand-built nodes are returned as they are. Type annotations on values and
the number kind are dropped.

=head1 INTERNAL METHODS

C<_new_parsed> is the constructor used by the tree builder; it may change
without notice.

=head1 SEE ALSO

L<Text::KDL::XS>, L<Text::KDL::XS::Value>, L<Text::KDL::XS::Document>,
L<Text::KDL::XS::Cookbook/"Building nodes and values by hand">.

=head1 AUTHOR

Davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 LICENSE

Copyright (C) 2026 Davenonymous.

This Perl distribution is licensed under the same terms as Perl itself.

=cut
