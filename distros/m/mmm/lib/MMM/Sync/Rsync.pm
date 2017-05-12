package MMM::Sync::Rsync;

use strict;
use warnings;
our @ISA = qw(MMM::Sync);

=head1 NAME

MMM::Sync::Rsync

=cut

sub buildcmd {
    my ($self) = @_;

    my @command = ('rsync');

    if ($self->{options}{rsync_defaults}) {
        push(@command, split(/ +/, $self->{options}{rsync_defaults}));
    } else { push(@command, '-aH'); }
    
    if ($self->{options}{rsync_opts}) {
        push(@command, split(/ +/, $self->{options}{rsync_opts}));
    }

    if ($self->{options}{exclude}) {
        foreach ( map { split( m/ /, $_ ) } $self->{options}{exclude} ) {
            push( @command, '--exclude', $_ );
        }
    }

    my %mo = (
        partialdir => 'partial-dir',
        tempdir => 'temp-dir',
    );
    push(@command, map {
        $self->{options}{$_} 
            ? '--' . ($mo{$_} || $_)
            : ()
        } (qw(delete-after delete delete-excluded)));
    push(@command, map {
        $self->{options}{$_}
            ? ('--' . ($mo{$_} || $_), $self->{options}{$_})
            : ()
        } (qw(partialdir tempdir))
    );
    push(@command, '--partial') if ($self->{options}{partialdir});

    push(@command, '-e', 'ssh') if ($self->{options}{use_ssh});

    push( @command,
        $self->{source},
        $self->{dest}
    );

    $ENV{RSYNC_PASSWORD} = $self->{options}{password} || '-'; # Avoid passwd prompt

    return @command;
}

sub _analyze_output {
    my ($self, $src, $line) = @_;
    if ($src eq 'STDERR') {
        return $line;
    } elsif ($line =~ /vanished|error|permission denied/i) {
        return $line
    } else {
        return;
    }
}

sub _exitcode {
    my ($self, $exitstatus) = @_;

    return 0 if (! $exitstatus);
    # Handle system exit code
    # if (grep { ($? & 127) == $_ } ()) {
    # }
    
    # Rsync exit code - no way to retry
    if (
        grep { ( $exitstatus ) == $_ } (
            1,    # Syntax or usage error
            2,    # Protocol incompatibility
            20,    # SIGUSR1 ou SIGINT reçu
        )
      )
    {
        return ( 2 );
    }

    # This is not a failure, but normal state
    if (
        grep { ( $exitstatus ) == $_ } (
            25,    # The --max-delete limit stopped deletions
        )
      )
    {
        return ( 0 );
    }
    return ( 1 );
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
