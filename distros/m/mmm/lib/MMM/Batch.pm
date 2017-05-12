package MMM::Batch;

use strict;
use warnings;

use base qw(MMM);
use base qw(MMM::Report::Mail);

=head1 NAME

MMM::Batch

=head1 SYNOPSIS

    use MMM::Batch;
    my $mmm = MMM::Batch->new() or die "Cannot find MMM installation";
    $mmm->run();

=head1 DESCRIPTION

A daemon for mmm system

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

sub run {
    my ( $self ) = @_;

    $self->load();

    my @started_tasks = ();
    foreach my $q ($self->get_tasks_by_name($self->list_tasks)) {
        $q->is_disable() and next;
        $q->frequency or next;
        $q->next_run_time <= scalar(time) or next;
        push(@started_tasks, $q->name);
        $self->_run_fork($q);
    }

    if (@started_tasks) {
        $self->log('DEBUG', 'Started tasks: %s', join(', ', @started_tasks));
    } else {
        $self->log('INFO', 'No task need to be run currently');
    }

    $self->_reap_message();
    $self->_reap_child();

    if ( $self->configval( 'default', 'publish_list' ) ) {
        $self->write_list();
    }
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
