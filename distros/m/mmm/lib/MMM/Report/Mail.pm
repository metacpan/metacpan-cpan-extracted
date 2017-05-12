package MMM::Report::Mail;

use strict;
use base qw(MMM::Report);
use Mail::Send;

=head1 NAME

MMM::Report::Console

=head1 SYNOPSIS

    use MMM::Report::Console;
    my $mmm = MMM::Report::Console->new( configfile => $file );
    $mmm->run();

=head1 DESCRIPTION

Produce textual report of MMM work done.

=head1 SEE ALSO

L<MMM>
L<MMM::Report>
L<MMM::Html>

=cut

sub body_queue {
    my ($self, $queue, %info) = @_;
    my $fh = $self->_get_mail_send() or return;
    %info = $queue->state_info() if (!keys %info);
    print $fh sprintf("%s (%s)\n", $queue->name, $queue->dest);
    print $fh sprintf("  last %s end %s\n",
        $info{job}{success} ? 'mirror' : 'try',
        $info{job}{end} ? scalar (gmtime($info{job}{end})) : '(N/A)',
    );
    if (!$info{job}{success} && $info{success}{end}) {
        print $fh sprintf("  last mirror succefully done %s\n", scalar (gmtime($info{success}{end})));
    }
    print $fh "\n";
}

sub run {
    my ($self) = @_;
    MMM::Report::run($self);
    $self->_send_mail();
}

sub _get_mail_send {
    my ($self) = @_;
    $self->{mailsend} ||= Mail::Send->new(
        To => $self->configval( 'default', 'mailto' ) || $ENV{USER},
        Subject => 'MMM Report from ' . $self->hostname
    );
    $self->{fh} ||= $self->{mailsend}->open;
}

sub _send_mail {
    my ($self) = @_;
    my $fh = $self->{fh} or return;
    print $fh sprintf("\n-- \nMMM :: %s\n", $MMM::VERSION);
    $fh->close;
}

1;

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

