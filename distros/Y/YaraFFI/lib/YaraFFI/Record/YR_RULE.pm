package YaraFFI::Record::YR_RULE;

$YaraFFI::Record::YR_RULE::VERSION   = '0.07';
$YaraFFI::Record::YR_RULE::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

YaraFFI::Record::YR_RULE - FFI Record for YARA rule structure

=head1 VERSION

Version 0.07

=head1 SYNOPSIS

    use YaraFFI::Record::YR_RULE;

    # In YARA callback, cast rule pointer to record
    my $rule = $ffi->cast('opaque', 'record(YaraFFI::Record::YR_RULE)*', $rule_ptr);

    # Access rule fields safely
    my $name_ptr = $rule->identifier;
    my $metas_ptr = $rule->metas;
    my $strings_ptr = $rule->strings;

=head1 DESCRIPTION

Represents the YR_RULE structure from YARA's libyara. This is a partial
definition focusing on commonly accessed fields. The actual YARA structure
is larger and more complex.

=head1 STRUCTURE FIELDS

=over 4

=item g_flags (sint32)

Global flags for the rule

=item t_flags (sint32)

Thread-specific flags

=item identifier (opaque)

Pointer to the rule name string

=item tags (opaque)

Pointer to tags array

=item metas (opaque)

Pointer to metadata array (YR_META structures)

=item strings (opaque)

Pointer to strings array (YR_STRING structures)

=item ns (opaque)

Pointer to namespace structure

=back

=cut

use v5.14;
use strict;
use warnings;
use FFI::Platypus::Record;

# YR_RULE structure (partial - only fields we can safely access)
record_layout_1(
    sint32 => 'g_flags',       # Global flags
    sint32 => 't_flags',       # Thread flags
    opaque => 'identifier',    # Pointer to rule name string
    opaque => 'tags',          # Pointer to tags
    opaque => 'metas',         # Pointer to metadata array
    opaque => 'strings',       # Pointer to strings array
    opaque => 'ns',            # Pointer to namespace
);

1; # End of YaraFFI::Record::YR_RULE
