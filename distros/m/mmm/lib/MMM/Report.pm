package MMM::Report;

use strict;
use warnings;
use base qw(MMM);

=head1 NAME

MMM::MirrorQueue

=head1 METHODS

=cut

sub new {
    my ($class, @args) = @_;
    my $mmm = $class->SUPER::new(@args) or return;

    if (!$mmm->{nofork}) {
        Sys::Syslog::openlog('mmm', 'pid', $mmm->configval('default', 'syslog_facilities', 'daemon'));
        $mmm->{use_syslog} = 1;
    }

    $mmm
}

=head2 header

Return the string to show at the beginning

=cut

sub header {
}

=head2 body

=cut

sub body {
}

=head2 body_queue

Return a string about body of each queue

=cut

sub body_queue {
}

=head2 footer

Return the string to show at the end

=cut

sub footer {
}

=head2 run

The main routine

=cut

sub run {
    my ($self) = @_;
    foreach my $q ($self->get_tasks_by_name($self->list_tasks)) {
        push(@{$self->{tasks}}, [ $q, { $q->state_info() } ]);
    }
    $self->header();
    foreach my $q (sort { $a->[0]->name cmp $b->[0]->name }
        @{$self->{tasks} || []}) {
        $q->[0]->is_disable and next;
        $self->body_queue($q->[0], %{ $q->[1] || {} });
    }
    $self->footer();
    $self->{tasks} = undef;
}

1;

__END__

=head1 SEE ALSO

L<MMM>

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

