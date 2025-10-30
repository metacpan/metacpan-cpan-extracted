package YaraFFI::Record::YR_STRING;

$YaraFFI::Record::YR_STRING::VERSION   = '0.06';
$YaraFFI::Record::YR_STRING::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

YaraFFI::Record::YR_STRING - FFI Record for YARA string structure

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

    use YaraFFI::Record::YR_STRING;

    # Cast string pointer to record
    my $string = $ffi->cast('opaque', 'record(YaraFFI::Record::YR_STRING)*', $str_ptr);

    # Access identifier
    my $id_ptr = $string->identifier;

=head1 DESCRIPTION

Represents the YR_STRING structure from YARA's libyara. This is a partial
definition focusing on the identifier field we need to access.

=head1 STRUCTURE FIELDS

=over 4

=item identifier (opaque)

Pointer to the string identifier (e.g., "$a", "$suspicious")

=back

=cut

use v5.14;
use strict;
use warnings;
use FFI::Platypus::Record;

# Partial definition - only the first field we need
record_layout_1(
    opaque => 'identifier',  # Pointer to string identifier
);

1; # End of YaraFFI::Record::YR_STRING
