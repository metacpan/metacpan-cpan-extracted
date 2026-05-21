package Text::KDL::XS::Emitter;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use B ();

# Tree-emit entry point:
#   $string = Text::KDL::XS::Emitter->_emit_tree($tree, %opts)
#
# Two modes, dispatched on input type:
#
#   * Tree mode (explicit, full fidelity):
#       - Text::KDL::XS::Document
#       - Text::KDL::XS::Node
#       - arrayref whose elements are all Text::KDL::XS::Node objects
#
#   * Data mode (auto-convert plain Perl data):
#       - any other HASH ref or ARRAY ref
#
# Data-mode mapping is documented in L</_emit_data_pair>.
sub _emit_tree {
    my ($class, $tree, %opts) = @_;

    my $version = $opts{version} // 'detect';
    my $version_int
        = $version eq '1'      ? 1
        : $version eq '2'      ? 2
        : $version eq 'detect' ? 0
        : Carp::croak("emit_kdl: unknown version '$version'");

    my $indent          = defined $opts{indent}          ? $opts{indent}          : -1;
    my $escape_mode     = defined $opts{escape_mode}     ? $opts{escape_mode}     : -1;
    my $identifier_mode = defined $opts{identifier_mode} ? $opts{identifier_mode} : -1;

    my $emitter = $class->_new($version_int, $indent, $escape_mode, $identifier_mode);

    my $blessed = Scalar::Util::blessed($tree) // '';
    if ($blessed eq 'Text::KDL::XS::Document') {
        _emit_node_recursive($emitter, $_) for @{ $tree->nodes };
    }
    elsif ($blessed eq 'Text::KDL::XS::Node') {
        _emit_node_recursive($emitter, $tree);
    }
    elsif (_is_node_array($tree)) {
        _emit_node_recursive($emitter, $_) for @$tree;
    }
    elsif (ref($tree) eq 'HASH' || ref($tree) eq 'ARRAY') {
        _emit_data($emitter, $tree);
    }
    else {
        Carp::croak("emit_kdl: expected Document, Node, ARRAY ref, or HASH ref");
    }

    $emitter->_emit_end;
    return $emitter->_get_buffer;
}

sub _is_node_array {
    my ($x) = @_;
    return 0 unless ref($x) eq 'ARRAY';
    for my $el (@$x) {
        my $b = Scalar::Util::blessed($el);
        return 0 unless $b && $el->isa('Text::KDL::XS::Node');
    }
    return @$x ? 1 : 0;   # empty array goes to data mode (trivially empty)
}

# ---------------------------------------------------------------------------
# Tree mode (explicit)
# ---------------------------------------------------------------------------

sub _emit_node_recursive {
    my ($emitter, $node) = @_;

    Carp::croak("emit_kdl: tree mode expects Text::KDL::XS::Node, got "
        . (ref($node) || 'scalar'))
        unless Scalar::Util::blessed($node) && $node->isa('Text::KDL::XS::Node');

    $emitter->_emit_node($node->name, $node->type_annotation);

    $emitter->_emit_arg(_value_to_payload($_)) for @{ $node->args };

    for my $pair (@{ $node->props }) {
        my ($key, $value) = @$pair;
        $emitter->_emit_property($key, _value_to_payload($value));
    }

    my $children = $node->children;
    if (@$children) {
        $emitter->_start_children;
        _emit_node_recursive($emitter, $_) for @$children;
        $emitter->_finish_children;
    }
}

sub _value_to_payload {
    my ($v) = @_;

    if (Scalar::Util::blessed($v) && $v->isa('Text::KDL::XS::Value')) {
        return {
            type            => $v->{type},
            kind            => $v->{kind},
            value           => $v->{value},
            type_annotation => $v->{type_annotation},
        };
    }
    return _coerce_scalar_to_payload($v);
}

# ---------------------------------------------------------------------------
# Data mode (auto-convert plain Perl data)
# ---------------------------------------------------------------------------

# Convention: a top-level arrayref becomes a series of anonymous nodes named
# "-" (the same convention used by JSON-in-KDL). Top-level hashrefs become
# a series of nodes, one per key, in sorted-key order for deterministic
# output.
sub _emit_data {
    my ($emitter, $data) = @_;

    if (ref($data) eq 'HASH') {
        for my $key (sort keys %$data) {
            _emit_data_pair($emitter, $key, $data->{$key});
        }
        return;
    }

    if (ref($data) eq 'ARRAY') {
        for my $item (@$data) {
            _emit_data_pair($emitter, '-', $item);
        }
        return;
    }

    Carp::croak("emit_kdl: top-level data must be HASH or ARRAY ref");
}

# Emit one (name, value) pair according to the documented mapping:
#
#   scalar / undef / bool         -> `name <value>`
#   []                            -> bare `name`
#   [ scalars... ]                -> `name <v1> <v2> ...`
#   { ... }                       -> `name { children }`
#   [ $non_scalar, ... ]          -> repeated sibling `name`s (one per element)
#
# Mixed arrays (some scalars, some refs) repeat the sibling form for each
# element, scalars included.
sub _emit_data_pair {
    my ($emitter, $name, $value) = @_;

    if (!ref($value) || _is_bool_object($value) || _is_value_object($value)) {
        $emitter->_emit_node($name, undef);
        $emitter->_emit_arg(_value_to_payload($value));
        return;
    }

    if (ref($value) eq 'HASH') {
        $emitter->_emit_node($name, undef);
        if (%$value) {
            $emitter->_start_children;
            for my $k (sort keys %$value) {
                _emit_data_pair($emitter, $k, $value->{$k});
            }
            $emitter->_finish_children;
        }
        return;
    }

    if (ref($value) eq 'ARRAY') {
        if (!@$value) {
            $emitter->_emit_node($name, undef);
            return;
        }

        my $all_scalar = !grep { _is_complex($_) } @$value;
        if ($all_scalar) {
            $emitter->_emit_node($name, undef);
            $emitter->_emit_arg(_value_to_payload($_)) for @$value;
            return;
        }

        # Mixed/complex: repeat the sibling for each element.
        _emit_data_pair($emitter, $name, $_) for @$value;
        return;
    }

    Carp::croak("emit_kdl: cannot serialize " . ref($value) . " ref");
}

sub _is_complex {
    my ($v) = @_;
    return 0 unless ref $v;
    return 0 if _is_bool_object($v);
    return 0 if _is_value_object($v);
    return 1;
}

sub _is_bool_object {
    my ($v) = @_;
    my $b = Scalar::Util::blessed($v);
    return 0 unless $b;
    return $b eq 'JSON::PP::Boolean'
        || $b eq 'Types::Serialiser::Boolean'
        || $b eq 'JSON::Boolean'
        || $b eq 'boolean'
        || $b eq 'Mojo::JSON::_Bool';
}

sub _is_value_object {
    my ($v) = @_;
    my $b = Scalar::Util::blessed($v);
    return $b && $b eq 'Text::KDL::XS::Value';
}

# Coerce a plain Perl scalar (or bool object) into the C-friendly payload
# hash that the XS layer consumes.
#
#   undef                                  -> KDL null
#   JSON::PP::true / Types::Serialiser::*  -> KDL bool
#   integer-flagged SV                     -> KDL number (integer)
#   float-flagged SV                       -> KDL number (float)
#   any other scalar                       -> KDL string
#
# Strings such as "true"/"false" are NOT heuristically promoted to booleans;
# pass an explicit JSON::PP::true / JSON::PP::false if you mean a bool.
sub _coerce_scalar_to_payload {
    my ($v) = @_;

    return { type => 'null', value => undef } unless defined $v;

    if (_is_bool_object($v)) {
        return { type => 'bool', value => ($v ? 1 : 0) };
    }

    if (Scalar::Util::blessed($v)) {
        # Stringifiable objects (Math::BigInt, URIs, etc.) - preserve as string.
        return { type => 'string', value => "$v" };
    }

    Carp::croak("emit_kdl: refs cannot appear as a single scalar value here")
        if ref $v;

    my $flags = B::svref_2object(\$v)->FLAGS;
    my $is_string_only = ($flags & B::SVf_POK()) && !($flags & (B::SVf_IOK() | B::SVf_NOK()));

    return { type => 'string', value => "$v" } if $is_string_only;

    if ($flags & B::SVf_IOK()) {
        return { type => 'number', kind => 'integer', value => 0 + $v };
    }
    if ($flags & B::SVf_NOK()) {
        return { type => 'number', kind => 'float', value => 0 + $v };
    }

    return { type => 'string', value => "$v" };
}

1;

__END__

=head1 NAME

Text::KDL::XS::Emitter - internal KDL emitter helpers (no public API)

=head1 DESCRIPTION

This module is an implementation detail of L<Text::KDL::XS>. It contains
the Perl half of the emitter pipeline that bridges Perl data structures
and the underlying C emitter exposed by the XS layer. All subroutines
in this package are private (prefixed with an underscore) and may
change without notice.

End users should call L<Text::KDL::XS/emit_kdl> instead.

=head1 SEE ALSO

L<Text::KDL::XS>

=head1 LICENSE

This Perl distribution is released under the same terms as Perl itself.

=cut

