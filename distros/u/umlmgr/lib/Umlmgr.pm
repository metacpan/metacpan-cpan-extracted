package Umlmgr;

use 5.010000;
use strict;
use warnings;
use base qw(Config::IniFiles);
use Umlmgr::Uml;
use Sys::Syslog;
use IPC::Open3;

our $VERSION = '0.10';

sub new {
    my ($class, %options) = @_;

    my ($config) = grep {
        $_
    } ($options{config} || ($> != 0 ? "$ENV{HOME}/.umlmgr/config" : '/etc/umlmgr.cfg'));
    my $self;
    eval {
    $self = $class->SUPER::new(
        (-f $config ? (-file => $config) : ()),
    );
    };

    $self or return;
    bless($self, $class);
}

sub machinesdir {
    my ($self) = @_;
    $self->val('machines', 'dir', "$ENV{HOME}/.umlmgr/");
}

sub list_machines_config {
    my ($self) = @_;
    if (opendir(my $dh, $self->machinesdir)) {
        my @list;
        while(my $f = readdir($dh)) {
            $f =~ /(.+)\.uml$/ or next;
            push(@list, $1);
        }
        closedir($dh);
        return(@list);
    } else {}
}

sub get_machine {
    my ($self, $name) = @_;
    return Umlmgr::Uml->new(
        $self->machinesdir . "/$name.uml",
        user => $self->val('env', 'user'),
    );
}

sub setup_network {
    my ($self) = @_;

    if ($> == 0 && ! $self->val('env', 'user')) {
        warn "No user defined, running vm as root is a bad idea\n";
        return;
    }

    Sys::Syslog::openlog('umlmgr', 'pid', 'daemon');
    if (my $tap = $self->val('network', 'tap')) {
        my $id = $self->val('env', 'user')
            ? Umlmgr::Utils::get_id($self->val('env', 'user'))
            : undef;
        system(
            'tunctl',
            ($id ? ('-u', $id) : ()),
            '-t', $tap
        );
    }
    if ($self->val('network', 'switch')) {
        my $pid = fork;
        return if(!defined $pid);
        if ($pid) {
        } else {
            Umlmgr::Utils::become_user($self->val('env', 'user'))
                if ($self->val('env', 'user'));
            close(STDIN);
            #close(STDOUT);
            exec(join(' ', map { quotemeta($_) }
                ('uml_switch',
                ($self->val('network', 'hub') ? ('-hub') : ()),
                ($self->val('network', 'tap')
                    ? ('-tap', $self->val('network', 'tap'))
                    : ()),
                )) . ' < /dev/null > /dev/null'
            );
            exit(0);
        }
    }
}

sub start {
    my ($self) = @_;
    foreach my $m ($self->list_machines_config) {
        my $ma = $self->get_machine($m);
        $ma->onboot or next;
        $ma->status and next;
        $ma->start;
    }
}

sub stop {
    my ($self) = @_;
    foreach my $m ($self->list_machines_config) {
        my $ma = $self->get_machine($m);
        $ma->stop;
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
