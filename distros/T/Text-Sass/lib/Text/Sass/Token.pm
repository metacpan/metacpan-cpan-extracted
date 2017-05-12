# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        annulen
# Last Modified: $Date$
# Id:            $Id$
# $HeadURL$
#
package Text::Sass::Token;
use strict;
use warnings;
use Readonly;

our $VERSION = q[1.0.4];

# TODO: Use token patterns from original sass and use them consistently

Readonly our $ESCAPE => qr/\\./smx;
Readonly our $NMCHAR => qr/[^\s:\\]|$ESCAPE/smx;
Readonly our $IDENT  => qr/(?:$NMCHAR)+/smx;

# Next patterns are already consistent with Sass

Readonly our $COMMENT             => qr{/[*]([^*]|[*]+[^*])*[*]*[*]/}smx;
Readonly our $SINGLE_LINE_COMMENT => qr{\s//.*}mx; ## no critic (RequireDotMatchAnything)

1;
__END__

=encoding utf8

=head1 NAME

Text::Sass::Token

=head1 VERSION

=head1 SYNOPSIS

  use Text::Sass::Token;

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 DEPENDENCIES

=over

=item L<Readonly|Readonly>

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

See README

=head1 SEE ALSO

=head1 AUTHOR

Roger Pettett E<lt>rmp@psyphi.netE<gt>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 LICENSE AND COPYRIGHT

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut
