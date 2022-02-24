package WebService::KvKAPI::Formatters;
our $VERSION = '0.101';
use warnings;
use strict;

# ABSTRACT: Utility package for formatting common numbers

use Exporter qw(import);

our @EXPORT_OK = qw(
    format_rsin
    format_location_number
    format_kvk_number
);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub format_kvk_number {
    return sprintf("%08d", shift);
}

sub format_location_number {
    return sprintf("%012d", shift);
}

sub format_rsin {
    return sprintf("%09d", shift);
}

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::KvKAPI::Formatters - Utility package for formatting common numbers

=head1 VERSION

version 0.101

=head1 DESCRIPTION

Format the various numbers for use in the API calls

=head1 METHODS

=head2 format_kvk_number

Format a chamber of commerce number to 8 digits

=head2 format_location_number

Format a chamber of commerce location number to 12 digits

=head2 format_rsin

Format a chamber of commerce RSIN number to 9 digits

=head1 AUTHOR

Wesley Schwengle <wesley@mintlab.nl>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Mintlab / Zaaksysteem.nl.

This is free software, licensed under:

  The European Union Public License (EUPL) v1.1

=cut
