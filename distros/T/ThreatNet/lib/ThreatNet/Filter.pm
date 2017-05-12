package ThreatNet::Filter;

=pod

=head1 NAME

ThreatNet::Filter - Interface for ThreatNet event filters

=head1 DESCRIPTION

ThreatNet data sources can potentially generate a hell of a lot of
events, and it's important to be able to filter these down to just
the events that matter.

Many of the filters are stateful. For example, the standard
L<ThreatNet::Filter::ThreatCache> module provides cache objects
that filter out any threats that have already been seen in the
previous hour. (or whatever the state period is).

=head1 METHODS

The filter API is quite simple, with only a few methods.

=cut

use strict;
use Params::Util '_INSTANCE';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.20';
}





#####################################################################
# Constructor

=pod

=head2 new ...

Since some categories of filter do not strictly need to be in the
form of an object, a default C<new> constructor is provided which just
creates an empty object.

Returns a new C<ThreatNet::Filter> object, or some sub-classes may
return C<undef> on error.

=cut

sub new {
	bless {}, shift;
}

=pod

=head2 keep $Message

The C<keep> method takes a L<ThreatNet::Message> object and examines
it to determine if the message should be kept, or filtered out.

In the default implementation of the filter, all messages are kept.

Returns true if the message should be kept, or false if the message
should be discarded.

=cut

sub keep { _INSTANCE($_[1], 'ThreatNet::Message') ? 1 : undef }

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ThreatNet-Filter>

For other issues, or commercial enhancement and support, contact the author

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<http://ali.as/threatnet/>, L<ThreatNet::Message>

=head1 COPYRIGHT

Copyright (c) 2004 - 2005 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
