package MMM::Report::Console;

use strict;
use base qw(MMM::Report);

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
    printf("%s (%s)\n", $queue->name, $queue->dest);
    printf("  last %s end %s\n",
        $info{job}{success} ? 'mirror' : 'try',
        $info{job}{end} ? scalar (gmtime($info{job}{end})) : '(N/A)',
    );
    if (!$info{job}{success} && $info{success}{end}) {
        printf("  last mirror succefully done %s\n", scalar (gmtime($info{success}{end})));
    }
    print "\n";
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

