package XAS::Lib::App;

our $VERSION = '0.05';

use Try::Tiny;
use Pod::Usage;
use Hash::Merge;
use Getopt::Long;

use XAS::Class
  debug      => 0,
  version    => $VERSION,
  base       => 'XAS::Base',
  mixin      => 'XAS::Lib::Mixins::Handlers',
  import     => 'CLASS',
  utils      => 'dotid',
  filesystem => 'File',
  vars => {
    PARAMS => {
      -throws   => { optional => 1, default => undef },
      -facility => { optional => 1, default => undef },
      -priority => { optional => 1, default => undef },
    }
  }
;

#use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub signal_handler {
    my $signal = shift;

    my $ex = XAS::Exception->new(
        type => 'xas.lib.app.signal_handler',
        info => 'process interrupted by signal ' . $signal
    );

    $ex->throw();

}

sub define_signals {
    my $self = shift;

    $SIG{'INT'}  = \&signal_handler;
    $SIG{'QUIT'} = \&signal_handler;

}

sub define_pidfile {
    my $self = shift;

}

sub define_daemon {
    my $self = shift;

}

sub run {
    my $self = shift;

    my $rc = 0;

    try {

        $self->define_signals();
        $self->define_daemon();
        $self->define_pidfile();

        $self->main();

    } catch {

        my $ex = $_;

        $rc = $self->exit_handler($ex);

    };

    return $rc;

}

sub main {
    my $self = shift;

    $self->log->warn('You need to override main()');

}

sub options {
    my $self = shift;

    return {};

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my $class = shift;

    my $self = $class->SUPER::init(@_);

    if (defined($self->throws)) {

        $self->env->throws($self->throws);
        $self->class->throws($self->throws);

    }

    if (defined($self->priority)) {

        $self->env->priority($self->priority);

    }

    if (defined($self->facility)) {

        $self->env->facility($self->facility);

    }

    my $options = $self->options();
    my $defaults = $self->_default_options();

    $self->_parse_cmdline($defaults, $options);

    return $self;

}

sub _default_options {
    my $self = shift;

    my $version = $self->CLASS->VERSION;
    my $script  = $self->env->script;

    return {
        'alerts!'  => sub { $self->env->alerts($_[1]); },
        'help|h|?' => sub { pod2usage(-verbose => 0, -exitstatus => 0); },
        'manual'   => sub { pod2usage(-verbose => 2, -exitstatus => 0); },
        'version'  => sub { printf("%s - v%s\n", $script, $version); exit 0; },
        'debug'    => sub { 
            $self->env->xdebug(1); 
            $self->log->level('debug', 1);
        },
        'priority=s' => sub {
            $self->env->priority($_[1]);
        },
        'facility=s' => sub {
            $self->env->facility($_[1]);
        },
        'log-file=s' => sub {
            my $logfile = File($_[1]);
            $self->env->log_type('file');
            $self->env->log_file($logfile);
            $self->log->activate();
        },
        'log-type=s' => sub { 
            $self->env->log_type($_[1]);
            $self->log->activate();
        },
        'log-facility=s' => sub { 
            $self->env->log_facility($_[1]); 
        },
    };

}

sub _parse_cmdline {
    my ($self, $defaults, $optional) = @_;

    my $hm = Hash::Merge->new('RIGHT_PRECEDENT');
    my %options = %{ $hm->merge($defaults, $optional) };

    GetOptions(%options) or pod2usage(-verbose => 0, -exitstatus => 1);

}

1;

__END__

=head1 NAME

XAS::Lib::App - The base class to write procedures within the XAS environment

=head1 SYNOPSIS

 use XAS::Lib::App;

 my $app = XAS::Lib::App->new();

 $app->run();

=head1 DESCRIPTION

This module defines a base class for writing procedures. It provides
signal handling, options processing, along with a exit handler.

=head1 METHODS

=head2 new

This method initializes the module. It inherits from L<XAS::Base|XAS::Base>
and takes these additional parameters:

=over 4

=item B<-throws>

This changes the default error message from "changeme" to something useful.

=item B<-facility>

This will change the facility of the alert. The default is 'systems'.

=item B<-priority>

This will change the priority of the alert. The default is 'low'.

=back

=head2 run

This method sets up a global exception handler and calls main(). The main() 
method will be passed one parameter: an initialized handle to this class.

Example

    sub main {
        my $self = shift;

        $self->log->debug('in main');

    }

=over 4

=item Exception Handling

If an exception is caught, the global exception handler will send an alert, 
write the exception to the log and returns an exit code of 1. 

=item Normal Completion

When the procedure completes successfully, it will return an exit code of 0. 

=back

To change this behavior you would need to override the exit_handler() method.

=head2 main

This is where your main line logic starts.

=head2 options

This method sets up additional cli options. Option handling is provided
by L<Getopt::Long|https://metacpan.org/pod/Getopt::Long>. To access these 
options you need to define accessors for them.

  Example

    use XAS::Class
      version   => '0.01',
      base      => 'XAS::Lib::App',
      accessors => 'widget'
    ;

    sub main {
        my $self = shift;

        $self->log->info('starting up');
        sleep(60);
        $self->log->info('shutting down');

    }

    sub options {
        my $self = shift;

        return {
            'widget=s' => sub {
                $self->{widget} = uc($_[1]);
            }
        };

    }

=head2 define_signals

This method sets up basic signal handling. By default this is only for the INT 
and QUIT signals.

Example

    sub define_signals {
        my $self = shift;

        $SIG{INT}  = \&signal_handler;
        $SIG{QUIT} = \&singal_handler;

    }

=head2 define_pidfile

This is an entry point to define a pid file.

=head2 define_daemon

This is an entry point so the procedure can daemonize.

=head2 signal_handler($signal)

This method is a default signal handler. By default it throws an exception. 
It takes one parameter.

=over 4

=item B<$signal>

The signal that was captured.

=back

=head1 OPTIONS

This module handles the following command line options.

=head2 --facility

Defines the facility to use. Defaults to 'systems'. This will override the
class parameter.

=head2 --priority

Defines the priority to use. Defaults to 'low'. This will override the
class parameter.

=head2 --debug

This toggles debugging output.

=head2 --[no]alerts

This toggles sending alerts. They are on by default.

=head2 --help

This prints out a short help message based on the procedures pod.

=head2 --manual

This displaces the procedures manual in the defined pager.

=head2 --version

This prints out the version of the module.

=head2 --log-type

What type of log to use. By default the log is displayed on the console. Log
types can be one of the following "console", "file", "json" or "syslog".

=head2 --log-facility

What log facility class to use. This follows syslog convention. By default 
the facility is "local6".

=head2 --log-file

The name of the log file. When --logfile is specified, it implies a log type 
of "file".

=head1 SEE ALSO

=over 4

=item L<XAS::Lib::App::Daemon|XAS::Lib::App::Daemon>

=item L<XAS::Lib::App::Service|XAS::Lib::App::Service>

=item L<XAS::Lib::App::Service::Unix|XAS::Lib::App::Service::Unix>

=item L<XAS::Lib::App::Service::Win32|XAS::Lib::App::Service::Win32>

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
