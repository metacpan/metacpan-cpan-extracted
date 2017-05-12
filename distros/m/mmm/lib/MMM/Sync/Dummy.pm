package MMM::Sync::Dummy;

use strict;
use warnings;
use MMM::Sync;
our @ISA = qw(MMM::Sync);

=head1 NAME

MMM::Sync::Rsync

=cut

sub buildcmd {
    my ($self) = @_;

    my @command = ('/bin/true');

    my ($proto, $server, @sequence) = split(m'/+', $self->{source});
    defined($self->{runcount}) ? ($self->{runcount}++) : ($self->{runcount} = 0);
    $self->{val_return} = $sequence[$self->{runcount}] || 0; 

    return @command;
}

sub _exitcode {
    my ($self, $exitstatus) = @_;

    return $self->{val_return} || 0;
}

1;

__END__

=head1 AUTHOR

Olivier Thauvin <nanardon@nanardon.zarb.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Olivier Thauvin

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=cut
