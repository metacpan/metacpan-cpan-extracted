package Text::TNetstrings::XS;
use strict;
use warnings;
use base qw(Exporter);

require XSLoader;

=head1 NAME

Text::TNetstrings::XS - Fast data serialization using typed netstrings.

=head1 VERSION

Version 1.2.0

=cut

use version 0.77; our $VERSION = version->declare("v1.2.0");

=head1 SYNOPSIS

An XS (C) implementation of the tagged netstring specification. The
interface is the same as documented in L<Text::TNetstrings>.

=head1 EXPORT

=over

=item C<encode_tnetstrings($data)>

=item C<decode_tnetstrings($data)>

=item C<:all>

The C<:all> tag exports all the above subroutines.

=back

=cut

our @EXPORT_OK = qw(encode_tnetstrings decode_tnetstrings);
our %EXPORT_TAGS = (
	"all" => \@EXPORT_OK,
);

XSLoader::load('Text::TNetstrings::XS', $VERSION);

=head1 AUTHOR

Sebastian Nowicki

=cut

1;
