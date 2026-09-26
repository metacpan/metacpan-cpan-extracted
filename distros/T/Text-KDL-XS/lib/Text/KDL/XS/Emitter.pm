package Text::KDL::XS::Emitter;

use strict;
use warnings;

use Carp ();
use Scalar::Util ();
use overload ();
use Text::KDL::XS ();

our @CARP_NOT = qw(
    Text::KDL::XS Text::KDL::XS::Document Text::KDL::XS::Node
    Text::KDL::XS::Parser Text::KDL::XS::Value
);

my %IS_OPTION        = map { $_ => 1 } qw(version indent escape_mode identifier_mode);
my %VERSION_CODE     = (detect => 0, 1 => 1, 2 => 2);
my $MAX_INDENT       = 64;
my $ESCAPE_MODE_BITS = 0x170;
my $QUOTE_ALL        = 1;

my @BOOLEAN_CLASSES = qw(JSON::PP::Boolean Types::Serialiser::Boolean JSON::Boolean boolean Mojo::JSON::_Bool);

my $NULL_PAYLOAD  = { type => 'null' };
my $TRUE_PAYLOAD  = { type => 'bool', value => 1 };
my $FALSE_PAYLOAD = { type => 'bool', value => 0 };

# emit_kdl. The document is written once through the XS emitter, which notes
# any name, key, annotation or string value that it would write bare although
# it reads back as a keyword or a number. Unless the caller chose an
# identifier_mode, such a document is written again with every identifier
# quoted.
sub _emit_tree {
    my ($class, $tree, @options) = @_;
    my $settings = _parse_settings(@options);

    my $emission = _write_document($class, $tree, $settings);
    $emission = _write_document($class, $tree, { %$settings, identifier_mode => $QUOTE_ALL })
        if $emission->{needs_quoting} && !defined $settings->{identifier_mode};
    return $emission->{text};
}

sub _parse_settings {
    my (@options) = @_;
    my $options = Text::KDL::XS::_parse_named_arguments('emit_kdl', 'option', \%IS_OPTION, @options);
    my $version = Text::KDL::XS::_normalize_version('emit_kdl', $options->{version});

    return {
        version         => $VERSION_CODE{$version},
        indent          => _integer_option('indent', $options->{indent}, $MAX_INDENT),
        escape_mode     => _escape_mode_option($options->{escape_mode}),
        identifier_mode => _integer_option('identifier_mode', $options->{identifier_mode}, 2),
    };
}

sub _integer_option {
    my ($name, $value, $maximum) = @_;
    return undef unless defined $value;
    Carp::croak("emit_kdl: $name must be an integer from 0 to $maximum, got '$value'")
        unless $value =~ /\A[0-9]+\z/ && $value <= $maximum;
    return $value;
}

sub _escape_mode_option {
    my ($value) = @_;
    return undef unless defined $value;
    Carp::croak("emit_kdl: escape_mode must be a combination of 0x10, 0x20, 0x40 and 0x170, got '$value'")
        unless $value =~ /\A[0-9]+\z/ && $value <= $ESCAPE_MODE_BITS && ($value & ~$ESCAPE_MODE_BITS) == 0;
    return $value;
}

# Writes the whole document with one XS emitter. Returns the text and
# whether it has to be written in quote-all mode to read back as written.
sub _write_document {
    my ($class, $tree, $settings) = @_;
    my $walk = { emitter => undef, on_path => {} };

    eval {
        $walk->{emitter} = $class->_new(
            $settings->{version},
            $settings->{indent}          // -1,
            $settings->{escape_mode}     // -1,
            $settings->{identifier_mode} // -1,
        );
        _write_top_level($walk, $tree);
        $walk->{emitter}->_emit_end;
        1;
    } or Text::KDL::XS::_rethrow($@, __FILE__);

    my $text = $walk->{emitter}->_get_buffer;
    return { text => length $text ? $text : "\n", needs_quoting => $walk->{emitter}->_needs_quoting };
}

sub _write_top_level {
    my ($walk, $tree) = @_;

    if (Scalar::Util::blessed($tree)) {
        if ($tree->isa('Text::KDL::XS::Document')) {
            _write_node($walk, $_) for @{ $tree->nodes };
            return;
        }
        if ($tree->isa('Text::KDL::XS::Node')) {
            _write_node($walk, $tree);
            return;
        }
    }
    elsif (ref $tree eq 'ARRAY' && _is_node_list($tree)) {
        _write_node($walk, $_) for @$tree;
        return;
    }
    elsif (_is_container($tree)) {
        local $walk->{on_path}{ _enter($walk, $tree) } = 1;
        if (ref $tree eq 'HASH') {
            _write_data_pair($walk, $_, $tree->{$_}) for sort keys %$tree;
        }
        else {
            _write_data_pair($walk, '-', $_) for @$tree;
        }
        return;
    }
    Carp::croak("emit_kdl: expected Document, Node, ARRAY ref, or HASH ref");
}

sub _is_node_list {
    my ($elements) = @_;
    return 0 unless @$elements;
    for my $element (@$elements) {
        return 0 unless Scalar::Util::blessed($element) && $element->isa('Text::KDL::XS::Node');
    }
    return 1;
}

# The address of a node, hash or array about to be written. Croaks when it is
# already being written further up, that is, when the structure is cyclic.
sub _enter {
    my ($walk, $reference) = @_;
    my $address = Scalar::Util::refaddr($reference);
    Carp::croak("emit_kdl: cyclic data structure") if $walk->{on_path}{$address};
    return $address;
}

# ---------------------------------------------------------------------------
# Tree mode
# ---------------------------------------------------------------------------

sub _write_node {
    my ($walk, $node) = @_;
    no warnings 'recursion';    # the depth of a tree is bounded by its builder

    Carp::croak("emit_kdl: tree mode expects Text::KDL::XS::Node, got " . (ref($node) || 'a plain scalar'))
        unless ref $node eq 'Text::KDL::XS::Node'
        || (Scalar::Util::blessed($node) && $node->isa('Text::KDL::XS::Node'));
    local $walk->{on_path}{ _enter($walk, $node) } = 1;

    my $emitter = $walk->{emitter};
    $emitter->_emit_node($node->name, $node->type_annotation);
    $emitter->_emit_arg(_payload_for($_)) for @{ $node->args };
    for my $property (@{ $node->props }) {
        Carp::croak("emit_kdl: a property must be a [ key => value ] pair") unless ref $property eq 'ARRAY';
        $emitter->_emit_property($property->[0], _payload_for($property->[1]));
    }

    my $children = $node->children;
    return unless @$children;
    $emitter->_start_children;
    _write_node($walk, $_) for @$children;
    $emitter->_finish_children;
}

# ---------------------------------------------------------------------------
# Data mode
# ---------------------------------------------------------------------------

# One node for a hash key or an array element: a single value becomes an
# argument, a hash becomes children, an array of single values becomes
# arguments, and an array holding hashes or arrays becomes one sibling node
# per element.
sub _write_data_pair {
    my ($walk, $name, $value) = @_;
    no warnings 'recursion';    # the depth of the data is the caller's

    my $emitter = $walk->{emitter};
    if (!_is_container($value)) {
        $emitter->_emit_node($name, undef);
        $emitter->_emit_arg(_payload_for($value));
        return;
    }

    local $walk->{on_path}{ _enter($walk, $value) } = 1;

    if (ref $value eq 'HASH') {
        $emitter->_emit_node($name, undef);
        return unless %$value;
        $emitter->_start_children;
        _write_data_pair($walk, $_, $value->{$_}) for sort keys %$value;
        $emitter->_finish_children;
        return;
    }

    if (grep { _is_container($_) } @$value) {
        _write_data_pair($walk, $name, $_) for @$value;
        return;
    }
    $emitter->_emit_node($name, undef);
    $emitter->_emit_arg(_payload_for($_)) for @$value;
}

# Plain hashes and arrays are structure; everything else is a single value.
sub _is_container {
    my ($value) = @_;
    my $type = ref $value;
    return $type eq 'HASH' || $type eq 'ARRAY';
}

# ---------------------------------------------------------------------------
# Values
# ---------------------------------------------------------------------------

# The payload the XS emitter reads for one argument or property value: a
# Text::KDL::XS::Value itself, or a hash with the same keys.
sub _payload_for {
    my ($value) = @_;

    return $NULL_PAYLOAD unless defined $value;
    return _scalar_payload($value) unless ref $value;

    my $class = Scalar::Util::blessed($value)
        // Carp::croak("emit_kdl: cannot serialize " . ref($value) . " ref");
    return $value if $class eq 'Text::KDL::XS::Value' || $value->isa('Text::KDL::XS::Value');
    return $value ? $TRUE_PAYLOAD : $FALSE_PAYLOAD if _is_boolean($value);
    return _bignum_payload($value) if $value->isa('Math::BigInt') || $value->isa('Math::BigFloat');
    return { type => 'string', value => "$value" } if overload::Method($value, '""');
    Carp::croak("emit_kdl: cannot serialize $class object");
}

# A plain scalar is a number when it has a numeric value whose Perl rendering
# is its string value (if it has one); otherwise it is a string.
sub _scalar_payload {
    my ($value) = @_;
    my $kind = Text::KDL::XS::_number_kind_of($value);
    return { type => 'number', kind => $kind, value => $value } if defined $kind;
    return { type => 'string', value => $value };
}

sub _bignum_payload {
    my ($number) = @_;
    Carp::croak("emit_kdl: cannot write the " . ref($number) . " $number as a KDL number")
        if $number->is_nan || $number->is_inf;
    return { type => 'number', kind => 'string', value => "$number" };
}

sub _is_boolean {
    my ($object) = @_;
    for my $class (@BOOLEAN_CLASSES) {
        return 1 if $object->isa($class);
    }
    return 0;
}

1;

__END__

=encoding utf-8

=head1 NAME

Text::KDL::XS::Emitter - Internal: the Perl half of the KDL emitter

=head1 SYNOPSIS

Do not use this module directly. Call L<Text::KDL::XS/emit_kdl>:

=for highlighter language=Perl

  use Text::KDL::XS qw(emit_kdl);
  my $text = emit_kdl($document_or_data, %options);

=for highlighter

=head1 DESCRIPTION

C<Text::KDL::XS::Emitter> contains the Perl side of the emitter: it walks a
L<Text::KDL::XS::Document> / L<Text::KDL::XS::Node> tree (tree mode) or a
plain Perl data structure (data mode), classifies each value (a
L<Text::KDL::XS::Value> is passed on as it is, anything else becomes a
small payload hash), and drives the XS wrapper around ckdl's
C<kdl_emitter>. The XS layer validates every name, key and value, formats
all numbers itself and lets ckdl produce the text.

All subroutines and methods in this package start with an underscore, are
private, and may change without notice between releases. The public
behaviour, including the data-mode mapping and scalar coercion rules, is
documented under L<Text::KDL::XS/emit_kdl>.

=head1 SEE ALSO

L<Text::KDL::XS>.

=head1 AUTHOR

Davenonymous E<lt>perl@davenonymous.comE<gt>

=head1 LICENSE

Copyright (C) 2026 Davenonymous.

This Perl distribution is licensed under the same terms as Perl itself.

=cut
