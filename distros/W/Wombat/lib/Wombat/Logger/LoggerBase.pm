# -*- Mode: Perl; indent-tabs-mode: nil; -*-

package Wombat::Logger::LoggerBase;

=pod

=head1 NAME

Wombat::Logger::LoggerBase - logger base class

=head1 SYNOPSIS

  package My::Logger;

  use base qw(Wombat::Logger::LoggerBase);

=head1 DESCRIPTION

Convenience base class for logger implementations. The only method
that must be implemented is C<write()>, plus any accessor methods
required for configuration, and C<start()> and C<stop()> if resources
must be initialized and cleaned up.

=cut

use fields qw(container level started);
use strict;
use warnings;

use constant FATAL => 0;
use constant ERROR => 1;
use constant WARNING => 2;
use constant INFO => 3;
use constant DEBUG => 4;

use constant LEVELS => {
                        FATAL => FATAL,
                        ERROR => ERROR,
                        WARNING => WARNING,
                        INFO => INFO,
                        DEBUG => DEBUG,
                       };

use Servlet::Util::Exception ();

=pod

=head1 CONSTRUCTOR

=over

=item new()

Construct and return a B<Wombat::Logger::LoggerBase> instance,
initializing fields appropriately. If subclasses override the
constructor, they must be sure to call

  $self->SUPER::new();

=back

=cut

sub new {
    my $self = shift;

    $self = fields::new($self) unless ref $self;

    $self->{container} = undef;
    $self->{level} = ERROR;
    $self->{started} = undef;

    return $self;
}

=pod

=head1 ACCESSOR METHODS

=over

=item getContainer()

Return the Container with which this Logger is associated.

=cut

sub getContainer {
    my $self = shift;

    return $self->{container};
}

=pod

=item setContainer($container)

Set the Container with which this Logger is associated.

B<Parameters:>

=over

=item $container

the Container with which this Logger is associated

=back

=cut

sub setContainer {
    my $self = shift;
    my $container = shift;

    $self->{container} = $container;

    return 1;
}

=pod

=item getLevel()

Return the verbosity level of this Logger.

=cut

sub getLevel {
    my $self = shift;

    return $self->{level};
}

=pod

=item setLevel($level)

Set the verbosity level of this Logger. Messages logged with a higher
verbosity than this will be silently ignored.

Allowable values in increasing order are:

=over

=item 'FATAL'

=item 'ERROR'

=item 'WARNING'

=item 'INFO'

=item 'DEBUG'

=back

The default level is 'ERROR'.

B<Parameters:>

=over

=item $level

the verbosity level, as a string

=back

B<Throws:>

=over

=item B<Servlet::Util::IllegalArgumentException>

if the specified log level is not one of the allowed values

=back

=cut

sub setLevel {
    my $self = shift;
    my $level = shift;

    my $match = uc $level;
    if (exists LEVELS->{$level}) {
        $self->{level} = LEVELS->{$level};
    } else {
        my $msg = "unsupported log level [$level]";
        Servlet::Util::IllegalArgumentException->throw($msg);
    }

    return 1;
}

=pod

=back

=head1 PUBLIC METHODS

=over

=item log($message, $exception, $level)

Send a message and/or an exception to the log destination. If a level
is specified, the Logger must be set to a verbosity level greater than
or equal to the specified level. If a level is not specified, the
message and/or exception will be logged unconditionally.

B<Parameters:>

=over

=item $message

an optional string message to log

=item $exception

an optional exception to log in stack trace form

=item $level

an optional log level

=back

=cut

sub log {
    my $self = shift;
    my $msg = shift;
    my $e = shift;
    my $level = shift;

    if (!defined $level ||
        $self->{level} >= LEVELS->{$level}) {
        $self->write("$msg\n") if $msg;

        if ($e) {
            $self->write($e);

            if ($e->isa('Servlet::ServletException')) {
                my $root = $e->getRootCause();
                if ($root) {
                    $self->write("----- Root Cause -----\n");
                    $self->write($root);
                }
            }
        }
    }

    return 1;
  }

=pod

=item write($string)

Write the specified string to the log destination. The default
implementation does nothing. Subclasses must override this method.

B<Parameters:>

=over

=item $string

the string to write to the log destination

=back

=cut

sub write {}

=pod

=back

=head1 LIFECYCLE METHODS

=over

=item start()

Prepare for the beginning of active use of this Logger. This method
must be called before any of the public methods of the component are
utilized. Subclasses should initialize logging resources with this
method.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the Logger cannot be started

=back

=cut

sub start {
    my $self = shift;

    if ($self->{started}) {
        throw Wombat::LifecycleException->new("logger already started");
    }

    $self->{started} = 1;

    return 1;
}

=pod

=item stop()

Gracefully terminate the active use of this Logger. This method must
be the last called on a given instance of this component. Subclasses
should release logging resources with this method.

B<Throws:>

=over

=item B<Wombat::LifecycleException>

if the Logger cannot be stopped

=back

=cut

sub stop {
    my $self = shift;

    unless ($self->{started}) {
        throw Wombat::LifecycleException->new("logger not started");
    }

    return 1;
}

1;
__END__

=pod

=back

=head1 SEE ALSO

L<Servlet::Util::Exception>,
L<Wombat::Exception>

=head1 AUTHOR

Brian Moseley, bcm@maz.org

=cut
