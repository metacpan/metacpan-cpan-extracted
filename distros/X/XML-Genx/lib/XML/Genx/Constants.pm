package XML::Genx::Constants;

use strict;
use warnings;

use XML::Genx;

use base 'Exporter';

our $VERSION = '0.22';
our @EXPORT_OK = qw(
  GENX_SUCCESS
  GENX_BAD_UTF8
  GENX_NON_XML_CHARACTER
  GENX_BAD_NAME
  GENX_ALLOC_FAILED
  GENX_BAD_NAMESPACE_NAME
  GENX_INTERNAL_ERROR
  GENX_DUPLICATE_PREFIX
  GENX_SEQUENCE_ERROR
  GENX_NO_START_TAG
  GENX_IO_ERROR
  GENX_MISSING_VALUE
  GENX_MALFORMED_COMMENT
  GENX_XML_PI_TARGET
  GENX_MALFORMED_PI
  GENX_DUPLICATE_ATTRIBUTE
  GENX_ATTRIBUTE_IN_DEFAULT_NAMESPACE
  GENX_DUPLICATE_NAMESPACE
  GENX_BAD_DEFAULT_DECLARATION
);

1;
__END__

=pod

=head1 NAME

XML::Genx::Constants - constants for genx

=head1 SYNOPSIS

  use XML::Genx::Constants qw( GENX_SEQUENCE_ERROR );
  my $w = XML::Genx->new;
  eval { $w->EndDocument };
  die "programmer error"
    if $@ && $w->LastErrorCode == GENX_SEQUENCE_ERROR;

=head1 DESCRIPTION

This module provides constants for use with XML::Genx.  They are
mostly used for verifying which exception that has been thrown.

=head1 EXPORTS

The following constants are available for exporting.

=over 4

=item GENX_SUCCESS

=item GENX_BAD_UTF8

=item GENX_NON_XML_CHARACTER

=item GENX_BAD_NAME

=item GENX_ALLOC_FAILED

=item GENX_BAD_NAMESPACE_NAME

=item GENX_INTERNAL_ERROR

=item GENX_DUPLICATE_PREFIX

=item GENX_SEQUENCE_ERROR

=item GENX_NO_START_TAG

=item GENX_IO_ERROR

=item GENX_MISSING_VALUE

=item GENX_MALFORMED_COMMENT

=item GENX_XML_PI_TARGET

=item GENX_MALFORMED_PI

=item GENX_DUPLICATE_ATTRIBUTE

=item GENX_ATTRIBUTE_IN_DEFAULT_NAMESPACE

=item GENX_DUPLICATE_NAMESPACE

=item GENX_BAD_DEFAULT_DECLARATION

=back

=head1 SEE ALSO

L<XML::Genx>, L<XML::Genx::Simple>.

A full explanation of what the constants mean is at
L<http://www.tbray.org/ongoing/When/200x/2004/02/20/GenxStatus#declarations>.

=head1 AUTHOR

Dominic Mitchell, E<lt>cpan (at) happygiraffe.netE<gt>

The genx library was created by Tim Bray L<http://www.tbray.org/>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Dominic Mitchell. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

=over 4

=item 1.

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

=item 2.

Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

=back

THIS SOFTWARE IS PROVIDED BY AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

The genx library is:

Copyright (c) 2004 by Tim Bray and Sun Microsystems.  For copying
permission, see L<http://www.tbray.org/ongoing/genx/COPYING>.

=head1 VERSION

@(#) $Id: Constants.pm 1270 2006-10-08 17:29:33Z dom $

=cut
