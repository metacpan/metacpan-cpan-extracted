package ThreatNet::Filter::Null;

=pod

=head1 NAME

ThreatNet::Filter::Null - ThreatNet Filter to discard all messages

=head1 DESCRIPTION

The default C<ThreatNet::Filter> object returns true for all messages
passed to its C<keep> method, and can thus be used as a logical "true"
filter object if needed.

C<ThreatNet::Filter::Null> is a utility class which provides the logical
opposite of this. Calls to the C<keep> method for Null filter objects
B<always> return false.

Its the bit bucket of the ThreatNet Filter world.

=head1 METHODS

Methods are as for the parent L<ThreatNet::Filter> class.

=cut

use strict;
use Params::Util '_INSTANCE';
use base 'ThreatNet::Filter';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}

sub keep {
	_INSTANCE($_[1], 'ThreatNet::Message') ? '' : undef;
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ThreatNet-Filter>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/threatnet/>, L<ThreatNet::Filter>

=head1 COPYRIGHT

Copyright (c) 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
