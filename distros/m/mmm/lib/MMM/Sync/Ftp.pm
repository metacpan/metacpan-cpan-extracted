package MMM::Sync::Ftp;

use strict;
use warnings;
our @ISA = qw(MMM::Sync);

sub buildcmd {
    my ($self) = @_;

    my @command = ('mirrordir', '--no-chown');

    if ($self->{options}{ftp_defaults}) {
        push(@command, split(/ +/, $self->{ftp_defaults}));
    }

    if ($self->{options}{exclude}) {
        foreach ( map { split( m/ /, $_ ) } $self->{options}{exclude} ) {
            push( @command, '--exclude-glob', $_ );
        }
    }

    if (!grep { $self->{options}{$_} } (qw(delete-after delete delete-excluded))) {
        push(@command, '--keep-files');
    }

    if ($self->{options}{tempdir}) {
        $ENV{TMPDIR} = $self->{options}{tempdir};
    }

    push( @command,
        $self->{source},
        $self->{dest}
    );

    if ($self->{options}{password}) {
        push(@command, '--password', $self->{options}{password});
    }

    return @command;
}

1;
