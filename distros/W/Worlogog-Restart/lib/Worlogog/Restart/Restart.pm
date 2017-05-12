package Worlogog::Restart::Restart;

use warnings;
use strict;

our $VERSION = '0.03';

sub DESTROY {}

sub new {
    my ($class, %self) = @_;
    bless \%self, $class
}

sub name { $_[0]{name} }
sub code { $_[0]{code} }

'ok'

__END__

=head1 NAME

Worlogog::Restart::Restart - restart objects (internal class)

=head1 DESCRIPTION

See L<C<find> in C<Worlogog::Restart>|Worlogog::Restart/find-RESTART>.

=head1 AUTHOR

Lukas Mai, C<< <l.mai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013, 2014 Lukas Mai.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
