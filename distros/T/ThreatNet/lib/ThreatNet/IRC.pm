package ThreatNet::IRC;

=pod

=head1 NAME

ThreatNet::IRC - ThreatNet IRC-specific classes

=head2 DESCRIPTION

The ThreatNet concept is not intended to be solely base on IRC, although it
is the primary IPC mechanism for linking nodes together.

C<ThreatNet::IRC> is a base module that provides most of the IRC-specific
classes.

At the present time, it contains only one class, L<ThreatNet::IRC::Envelope>.

=cut

use strict;
use ThreatNet::IRC::Envelope ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ThreatNet-IRC>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/threatnet/>

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

