package PPIx::Utilities;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.001000';


1;

__END__

=head1 NAME

PPIx::Utilities - Extensions to L<PPI|PPI>.


=head1 VERSION

This document describes PPIx::Utilities version 1.1.0.


=head1 SYNOPSIS

This module does nothing but act as a handle for the PPIx-Utilities
distribution.


=head1 DESCRIPTION

This is a collection of functions for dealing with L<PPI|PPI> objects, many of
which originated in L<Perl::Critic|Perl::Critic>.  They are organized into
modules by the kind of PPI class they relate to, by replacing the "PPI" at the
front of the module name with "PPIx::Utilities", e.g. functionality related to
L<PPI::Node|PPI::Node>s is in L<PPIx::Utilities::Node|PPIx::Utilities::Node>.


=head1 INTERFACE

None.


=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-ppix-utilities@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Elliot Shank  C<< <perl@galumph.com> >>


=head1 COPYRIGHT

Copyright (c) 2009-2010, Elliot Shank.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.


=cut

##############################################################################
#      $URL: http://perlcritic.tigris.org/svn/perlcritic/trunk/distributions/PPIx-Utilities/lib/PPIx/Utilities.pm $
#     $Date: 2010-12-01 20:31:47 -0600 (Wed, 01 Dec 2010) $
#   $Author: clonezone $
# $Revision: 4001 $
##############################################################################

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 70
#   indent-tabs-mode: nil
#   c-indentation-style: bsd
# End:
# ex: set ts=8 sts=4 sw=4 tw=78 ft=perl expandtab :
