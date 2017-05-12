package Test::Rsyslog;

use strict;
use warnings;
use File::Temp();
use Fcntl();
use File::Spec();
use FileHandle();
use English qw( -no_match_vars );
use Carp();
use POSIX();
use Config;

our $VERSION = '0.06';

sub _USER_READ_WRITE_PERMISSIONS         { return 600 }
sub _USER_READ_WRITE_EXECUTE_PERMISSIONS { return 700 }

sub socket_path {
    my ($self) = @_;
    return $self->{_socket_path};
}

sub messages {
    my ($self) = @_;
    my @messages;
    my $handle = FileHandle->new( $self->{_messages_path}, Fcntl::O_RDONLY() );
    if ($handle) {
        binmode $handle, ':encoding(UTF-8)';
        while ( my $line = <$handle> ) {
            chomp $line;
            push @messages, $line;
        }
    }
    elsif ( $OS_ERROR == POSIX::ENOENT() ) {
    }
    else {
        Carp::croak(
"Failed to open $self->{_messages_path} for reading:$EXTENDED_OS_ERROR"
        );
    }
    return @messages;
}

sub find {
    my ( $self, $string ) = @_;
    $string =~ s/([\x00-\x1F])/'#' . sprintf '%03o', ord $1/smxeg;
    my $quoted = quotemeta $string;
    my @found;
    foreach my $line ( $self->messages() ) {
        if ( $line =~ /$quoted/smx ) {
            push @found, $line;
        }
    }
    return @found;
}

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    my $root_directory = File::Temp::mktemp(
        File::Spec->catfile(
            File::Spec->tmpdir(), 'perl_test_rsyslog_XXXXXXXXXXX'
        )
    );
    if ( $root_directory =~ /^(.*perl_test_rsyslog_.*)$/smx ) {
        $self->{_root_directory} = $1;
    }
    else {
        Carp::croak("Unable to untaint the directory path of $root_directory");
    }
    mkdir $self->{_root_directory}, oct _USER_READ_WRITE_EXECUTE_PERMISSIONS()
      or Carp::croak(
        "Failed to mkdir $self->{_root_directory}:$EXTENDED_OS_ERROR");
    $self->{_socket_path} =
      File::Spec->catfile( $self->{_root_directory}, 'rsyslog.sock' );
    $self->{_messages_path} =
      File::Spec->catfile( $self->{_root_directory}, 'messages' );
    $self->{_pid_path} = File::Spec->catfile( $self->{_root_directory}, 'pid' );
    $self->{_config_path} =
      File::Spec->catfile( $self->{_root_directory}, 'rsyslog.conf' );
    my $config_handle = FileHandle->new(
        $self->{_config_path},
        Fcntl::O_WRONLY() | Fcntl::O_CREAT() | Fcntl::O_EXCL(),
        oct _USER_READ_WRITE_PERMISSIONS()
      )
      or Carp::croak(
        "Failed to open $self->{_config_path} for writing:$EXTENDED_OS_ERROR");
    $config_handle->print(
        <<"_CONF_") or Carp::croak("Failed to print to $self->{_config_path}:$EXTENDED_OS_ERROR");
\$ModLoad imuxsock
\$InputUnixListenSocketCreatePath on
\$AddUnixListenSocket $self->{_socket_path}
\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
\$OmitLocalLogging off
*.* $self->{_messages_path}
_CONF_
    $config_handle->close()
      or
      Carp::croak("Failed to close $self->{_config_path}:$EXTENDED_OS_ERROR");
    $self->start();
    return $self;
}

sub scrub {
    my ($self) = @_;
    if ( $self->alive() ) {
        Carp::croak('Unable to truncate while rsyslogd is still running');
    }
    truncate $self->{_messages_path}, 0
      or Carp::croak(
        "Failed to truncate $self->{_messages_path}:$EXTENDED_OS_ERROR");
    return;
}

sub start {
    my ($self) = @_;
    my $dev_null = File::Spec->devnull();
    if ( ( defined $self->{_pid} ) && ( kill 0, $self->{_pid} ) ) {
        Carp::cluck('Temporary rsyslog daemon is already running...');
        return;
    }
    if ( $self->{_pid} = fork ) {
        while ( not -e $self->{_socket_path} ) {
            sleep 1;
        }
    }
    elsif ( defined $self->{_pid} ) {

        eval {
            # clear any possible tainted environment variables
            local %ENV = %ENV;
            local $ENV{'PATH'} = '/usr/bin:/usr/sbin:/sbin:/bin:';
            delete $ENV{'BASH_ENV'};
            delete $ENV{'ENV'};
            delete $ENV{'IFS'};
            delete $ENV{'CDPATH'};
            open STDERR, q[>], $dev_null
              or die "Failed to redirect STDERR:$EXTENDED_OS_ERROR\n";
            open STDOUT, q[>], $dev_null
              or die "Failed to redirect STDOUT:$EXTENDED_OS_ERROR\n";
            exec {'rsyslogd'} 'rsyslogd', '-n', '-d',
              '-f' => $self->{_config_path},
              '-i' => $self->{_pid_path}
              or die "Failed to exec 'rsyslogd':$EXTENDED_OS_ERROR\n";
        } or do {
            chomp $EVAL_ERROR;
            warn "$EVAL_ERROR\n";
        };
        exit 1;
    }
    else {
        Carp::croak("Failed to fork:$EXTENDED_OS_ERROR");
    }
    return;
}

sub alive {
    my ($self) = @_;
    if ( $self->{_pid} ) {
        waitpid $self->{_pid}, POSIX::WNOHANG();
        if ( kill 0, $self->{_pid} ) {
            return 1;
        }
    }
    return 0;
}

sub stop {
    my ($self) = @_;
    if ( $self->{_pid} ) {
        my @signal_numbers = split q[ ], $Config{'sig_num'};
        my @signal_names   = split q[ ], $Config{'sig_name'};
        my %signals_by_name;
        my $signal_index = 0;
        foreach my $signal_name (@signal_names) {
            $signals_by_name{$signal_name} = $signal_numbers[$signal_index];
            $signal_index += 1;
        }
        if ( kill $signals_by_name{'TERM'}, $self->{_pid} ) {
            waitpid $self->{_pid}, 0;
        }
        elsif ( $OS_ERROR == POSIX::ESRCH() ) {
        }
        else {
            Carp::croak("Failed to kill $self->{_pid}:$EXTENDED_OS_ERROR");
        }
    }
    return;
}

sub DESTROY {
    my ($self) = @_;
    $self->stop();
    foreach my $key ( sort { $a cmp $b } keys %{$self} ) {
        if ( $key =~ /_path$/smx ) {
            unlink $self->{$key}
              or ( $OS_ERROR == POSIX::ENOENT() )
              or
              Carp::croak("Failed to unlink $self->{$key}:$EXTENDED_OS_ERROR");
        }
    }
    rmdir $self->{_root_directory}
      or ( $OS_ERROR == POSIX::ENOENT() )
      or Carp::croak(
        "Failed to rmdir $self->{_root_directory}:$EXTENDED_OS_ERROR");
    return;
}

1;
__END__
=head1 NAME

Test::Rsyslog - Creates a temporary instance of rsyslog to run tests against

=head1 VERSION

Version 0.06

=head1 SYNOPSIS
 
  my $rsyslog = Test::Rsyslog->new();

  Sys::Syslog::setlogsock({ type => 'unix', path => $rsyslog->socket_path() });
  # or "Sys::Syslog::setlogsock('unix', $rsyslog->socket_path());" for older Sys::Syslogs
  Sys::Syslog::openlog('program[' . $$ . ']','cons','LOG_LOCAL7');
  Sys::Syslog::syslog('info|LOG_LOCAL7','This is a test message');
  Sys::Syslog::closelog();

  ok($rsyslog->find('This is a test message'), 'Rsyslog is okay');
 
=head1 DESCRIPTION

This module allows easy creation and tear down of a rsyslog instance.  When the variable goes 
out of scope, the rsyslog instance is torn down and the file system objects it relies on are removed.

=head1 SUBROUTINES/METHODS

=head2 new

This method will setup and start the rsyslog instance.  It currently has no parameters, but this may change in response to feature requests

=head2 socket_path

This method returns that path to the UNIX file system socket that is connected to the current running instance of rsyslog

=head2 find($string)

This method searches the existing logs that rsyslog has processed to see if a message has been found matching $string.  It will return a list of every line in the log file that matches $string.

=head2 start

This method starts the rsyslog instance

=head2 stop

This method stops the rsyslog instance

=head2 alive

This method checks to make sure that the rsyslogd instance is still running

=head2 messages

This method returns the content of the rsyslogd log file

=head2 scrub

This method truncates the rsyslogd log file.  Rsyslogd must be stopped to truncate the log file

=head1 DIAGNOSTICS
 
=over
 
=item C<< Failed to open %s for reading >>
 
There has been a file system error trying to read from the rsyslog logfile.
 
=item C<< Failed to print to %s >>
 
There has been a file system error trying to write to the rsyslog configuration file.
 
=item C<< Failed to fork >>
 
The operating system was unable to fork a subprocess for use by the rsyslog daemon.
 
=item C<< Failed to rmdir %s >>
 
There has been a file system error trying to remove the temporary directory.
 
=item C<< Failed to unlink %s >>
 
There has been a file system error trying to unlink a temporary file
 
=item C<< Failed to close %s >>
 
There has been a file system error trying to close a temporary file
 
=item C<< Failed to mkdir %s >>
 
There has been a file system error trying to make the temporary directory
 
=item C<< Temporary rsyslog daemon is already running... >>
 
The rsyslog daemon has already started

=item C<< Unable to truncate while rsyslogd is still running >>
 
This module will not truncate the messages file while rsyslogd could still be writing to it

=item C<< Unable to untaint the directory path >>
 
The module generated an unrecognisable temporary path for rsyslogd

=back
 
=head1 CONFIGURATION AND ENVIRONMENT
 
Test::Rsyslog requires no configuration files or environment variables.
 
=head1 DEPENDENCIES
 
Test::Rsyslog requires Perl 5.6 or better.
 
=head1 INCOMPATIBILITIES
 
None reported
 
=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-test-rsyslog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Rsyslog>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Rsyslog


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Rsyslog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Rsyslog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Rsyslog>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Rsyslog/>

=back


=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of Test::Rsyslog
