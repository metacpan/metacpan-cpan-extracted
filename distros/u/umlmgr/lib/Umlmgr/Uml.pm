package Umlmgr::Uml;

use 5.010000;
use strict;
use warnings;
use Config::IniFiles;
use IPC::Open3;
use Sys::Syslog;
use Umlmgr::Utils;

sub new {
    my ($class, $config, %options) = @_;

    my $self = {};
    eval {
    $self->{config} = Config::IniFiles->new(
        -file => $config
    );
    };
    return if (! $self->{config}); 
    $self->{$_} = $options{$_} foreach (keys %options);
    ($self->{umid}) = $config =~ m:([^/]+)\.uml$:;
    Sys::Syslog::openlog('umlmgr', 'pid', 'daemon');
    bless($self, $class);
}

sub build_uml_cmd {
    my ($self) = @_;

    my @cmd;

    push(@cmd, $self->{config}->val('env', 'kernel', 'linux'));

    foreach my $param ($self->{config}->Parameters('uml')) {
        $self->{config}->val('uml', $param) or next;
        push(@cmd, $param . '=' . $self->{config}->val('uml', $param));
    }
    if (!$self->{config}->val('uml', 'umid')) {
        push(@cmd, "umid=$self->{umid}");
    }
    if (!$self->{config}->val('uml', 'con0')) {
        push(@cmd, 'con0=fd:0,fd:1');
    }
    if (!$self->{config}->val('uml', 'con')) {
        push(@cmd, 'con=pts');
    }

    return @cmd;
}

sub onboot {
    my ($self) = @_;
    $self->{config}->val('env', 'onboot')
}

sub id {
    my ($self) = @_;
    $self->{config}->val('uml', 'umid', $self->{umid});
}

sub start {
    my ($self) = @_;

    if ($> == 0 && !$self->{user}) {
        warn "No user defined, running vm as root is a bad idea\n";
        return;
    }

    my $pid = fork;
    return if (!defined($pid));

    if ($pid) {
        return 1; # we hope that's ok
    } else {
        if ($self->{user}) {
            Umlmgr::Utils::become_user($self->{user}) or return;
        }
        my @cmd = $self->build_uml_cmd;
        my $id = $self->id;
        $self->{config} = undef;
        Sys::Syslog::syslog('info', $id . ': Starting as ' . join(' ', @cmd));
        my $upid = open3(my $in, my $out, my $err, @cmd);
        while (my $line = <$out>) {
            chomp($line);
            Sys::Syslog::syslog('info', $id . " $line");
        }
        waitpid($upid, 0);
        Sys::Syslog::syslog('info', $id . " terminated with exit status $?");
        exit(0);
    }
}

sub stop {
    my ($self) = @_;

    if ($> == 0 && !$self->{user}) {
        warn "No user defined, running vm as root is a bad idea\n";
        return;
    }

    my $pid = fork;
    if (!defined($pid)) { return }
    if ($pid) {
        waitpid($pid, 0);
    } else {
    if ($self->{user}) {
        Umlmgr::Utils::become_user($self->{user}) or return;
    }
    Sys::Syslog::syslog('info', $self->id . ": sending halt");
    system('uml_mconsole', $self->id, 'halt');
    exit(0);
    }
}

sub status {
    my ($self) = @_;

    if ($> == 0 && !$self->{user}) {
        warn "No user defined, running vm as root is a bad idea\n";
        return;
    }

    my $pid = fork;
    return if (!defined($pid));
    if ($pid) {
        waitpid($pid, 0);
        return(($? >> 8) == 0);
    } else {
        if ($self->{user}) {
            Umlmgr::Utils::become_user($self->{user}) or return;
        }
        my $opid = open3(my $in, my $out, my $err, 'uml_mconsole', $self->id, 'version');
        waitpid($opid, 0);
        exit($? >> 8);
    }
}

sub get_console {
    my ($self, $console) = @_;
    
    if ($> == 0 && !$self->{user}) {
        warn "No user defined, running vm as root is a bad idea\n";
        return;
    }
    my $pid = fork;
    return if (!defined($pid));
    if ($pid) {
        waitpid($pid, 0);
        return(($? >> 8) == 0);
    } else {
        if ($self->{user}) {
            Umlmgr::Utils::become_user($self->{user}) or return;
        }
        my $pts;

        if (open(my $hd,
            join(' ', map { quotemeta($_) } 
            ('uml_mconsole', $self->id, 'config', $console)) . ' |')) {
            my $line = <$hd>;
            $line ||= '';
            chomp $line;
            ($pts) = $line =~ /^OK pts:(.*)/;
            close($hd);
        }
        if ($pts) {
            print "$pts\n";
        } else {
            warn "Can't find a valid console\n";
        }
    }
}

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Umlmgr - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Umlmgr;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Umlmgr, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Olivier Thauvin, E<lt>nanardon@localdomainE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Olivier Thauvin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
