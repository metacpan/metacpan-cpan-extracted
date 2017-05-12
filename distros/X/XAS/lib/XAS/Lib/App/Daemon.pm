package XAS::Lib::App::Daemon;

our $VERSION = '0.02';

use Try::Tiny;
use Pod::Usage;
use Hash::Merge;
use Getopt::Long;
use XAS::Lib::Pidfile;

use XAS::Class
  debug     => 0,
  version   => $VERSION,
  import    => 'class CLASS',
  base      => 'XAS::Lib::App',
  utils     => ':process dotid',
  constants => 'TRUE FALSE',
  accessors => 'daemon pid',
;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub define_signals {
    my $self = shift;

    $SIG{'INT'}  = \&signal_handler;
    $SIG{'QUIT'} = \&signal_handler;
    $SIG{'TERM'} = \&signal_handler;
    $SIG{'HUP'}  = \&signal_handler;

}

sub define_pidfile {
    my $self = shift;

    my $script = $self->env->script;

    $self->log->debug('entering define_pidfile()');

    $self->{'pid'} = XAS::Lib::Pidfile->new(-pid => $$);

    if (my $num = $self->pid->is_running()) {

        $self->throw_msg(
            dotid($self->class). '.define_pidfile.runerr',
            'pid_run_error',
            $script, $num
        );

    }

    $self->pid->write() or 
        $self->throw_msg(
            dotid($self->class) . '.define_pidfile.wrterr',
            'pid_write_error',
            $self->pid->file
        );

    $self->log->debug('leaving define_pidfile()');

}

sub define_daemon {
    my $self = shift;

    # become a daemon...
    # interesting, "daemonize() if ($self->daemon);" doesn't work as expected

    $self->log->debug("before pid = " . $$);

    if ($self->daemon) {

        daemonize();

    }

    $self->log->debug("after pid = " . $$);

}

sub run {
    my $self = shift;

    my $rc = $self->SUPER::run();

    $self->pid->remove();

    return $rc;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub _default_options {
    my $self = shift;

    my $options = $self->SUPER::_default_options();

    $self->env->log_type('file');
    $self->{'daemon'} = FALSE;

    $options->{'daemon'} = \$self->{daemon};

    $options->{'cfg-file=s'} = sub { 
        my $cfgfile = File($_[1]);
        $self->env->cfg_file($cfgfile);
    };

    $options->{'pid-file=s'} = sub { 
        my $pidfile = File($_[1]);
        $self->env->pid_file($pidfile);
    };

    return $options;

}

1;

__END__

=head1 NAME

XAS::Lib::App::Daemon - The base class to write daemons within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::App::Daemon;

 my $app = XAS::Lib::App::Daemon->new();

 $app->run();

=head1 DESCRIPTION

This module defines an operating environment for daemons. A daemon is a 
Unix background process without a controlling terminal. Windows really
doesn't have a concept for this behavior. For running background jobs
on Windows please see L<XAS::Lib::App::Services|XAS::Lib::App::Services>. 

This module is also single threaded, it doesn't use POE to provide an 
async environment. If you need that, then see the above module. This inherits 
from L<XAS::Lib::App|XAS::Lib::App>. Please see that module for additional 
documentation.

=head1 METHODS

=head2 define_pidfile

This method sets up the pid file for the process. By default, this file
is named $XAS_RUN/<$0>.pid. This can be overridden by the --pid-file option.

=head2 define_signals

This method sets up basic signal handling. By default this is only for the INT, 
TERM, HUP and QUIT signals.

=head2 define_daemon

This method will cause the process to become a daemon.

=head1 OPTIONS

This module handles these additional options.

=head2 --cfg-file

This defines an optional configuration file.

=head2 --pid-file

This defines the pid file for recording the pid.

=head2 --daemon

Become a daemon.

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::App|XAS::Lib::App>

=item L<XAS|XAS>

=back

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2015 Kevin L. Esteb

This is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0. For details, see the full text
of the license at http://www.perlfoundation.org/artistic_license_2_0.

=cut
