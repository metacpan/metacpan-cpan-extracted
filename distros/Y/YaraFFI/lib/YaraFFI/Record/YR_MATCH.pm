package YaraFFI::Record::YR_MATCH;

$YaraFFI::Record::YR_MATCH::VERSION   = '0.06';
$YaraFFI::Record::YR_MATCH::AUTHORITY = 'cpan:MANWAR';

=head1 NAME

YaraFFI::Record::YR_MATCH - FFI Record for YARA match structure

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

    use YaraFFI::Record::YR_MATCH;

    # Cast match pointer to record
    my $match = $ffi->cast('opaque', 'record(YaraFFI::Record::YR_MATCH)*', $match_ptr);

    # Access match details
    my $offset = $match->offset;
    my $length = $match->match_length;

=head1 DESCRIPTION

Represents the YR_MATCH structure from YARA's libyara. Contains information
about where a string pattern matched in the scanned data.

=head1 STRUCTURE FIELDS

=over 4

=item base (sint64)

Base offset

=item offset (sint64)

Byte offset where the match occurred

=item match_length (sint32)

Length of the matched data

=item data_length (sint32)

Length of additional data

=back

=cut

use v5.14;
use strict;
use warnings;
use FFI::Platypus::Record;

record_layout_1(
    sint64 => 'base',         # Base offset
    sint64 => 'offset',       # Match offset
    sint32 => 'match_length', # Length of match
    sint32 => 'data_length',  # Data length
);

1; # End of YaraFFI::Record::YR_MATCH
