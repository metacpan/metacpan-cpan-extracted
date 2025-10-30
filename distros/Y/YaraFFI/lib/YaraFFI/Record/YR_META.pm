package YaraFFI::Record::YR_META;

$YaraFFI::Record::YR_META::VERSION   = '0.06';
$YaraFFI::Record::YR_META::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

YaraFFI::Record::YR_META - FFI Record for YARA metadata structure

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

    use YaraFFI::Record::YR_META;
    use FFI::Platypus;

    my $ffi = FFI::Platypus->new(api => 2);

    # In a YARA callback, cast metadata pointer to record
    my $meta = $ffi->cast('opaque', 'record(YaraFFI::Record::YR_META)*', $meta_ptr);

    # Access fields safely
    my $type = $meta->type;
    my $id_ptr = $meta->identifier;

=head1 DESCRIPTION

Represents the YR_META structure from YARA's libyara. This allows safe
access to rule metadata through FFI::Platypus records.

=head1 STRUCTURE FIELDS

=over 4

=item type (sint32)

Metadata type: 1=INTEGER, 2=STRING, 3=BOOLEAN

=item identifier (opaque)

Pointer to the metadata identifier string

=item string (opaque)

Pointer to string value (when type is STRING)

=item integer (sint64)

Integer value (when type is INTEGER)

=back

=cut

use v5.14;
use strict;
use warnings;
use FFI::Platypus::Record;

record_layout_1(
    sint32  => 'type',        # META_TYPE_* constants
    sint32  => '_padding',    # Padding for alignment
    opaque  => 'identifier',  # Pointer to string
    opaque  => 'string',      # Pointer to string value (for string type)
    sint64  => 'integer',     # Integer value (for integer type)
);

1; # End of YaraFFI::Record::YR_META
