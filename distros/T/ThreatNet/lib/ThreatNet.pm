package ThreatNet;

use 5.005;
use strict;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}

# Load some common stuff
use ThreatNet::Topic;
use ThreatNet::Message;
use ThreatNet::Filter;

1;

=pod

=head1 NAME

ThreatNet - Pooled intelligence sharing of realtime hostile internet hosts

=head1 DESCRIPTION

This module is in hibernation for now, see L<ThreatNet::DATN2004> for the
original paper.

See L<ThreatNet::Bot::AmmoBot> for an example of a working ThreatNet bot.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ThreatNet>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2005 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
