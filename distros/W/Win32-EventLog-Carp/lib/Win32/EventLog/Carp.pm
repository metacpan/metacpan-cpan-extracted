package Win32::EventLog::Carp;

use strict;

# use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $LogEvals);

require Exporter;

@ISA       = qw( Exporter );
@EXPORT    = qw( confess carp croak );
@EXPORT_OK = qw( cluck click register_source );

$VERSION = '1.42';

require Carp;
require Carp::Heavy;

use File::Basename;
use File::Spec;

use Win32::EventLog qw(
  EVENTLOG_INFORMATION_TYPE EVENTLOG_WARNING_TYPE EVENTLOG_ERROR_TYPE
  EVENTLOG_AUDIT_SUCCESS EVENTLOG_AUDIT_FAILURE
);

my ( $EventLogHandle, $Source, $SourceFileName, $Register );

# We want to provide options on the 'use Win32::EventLog::Carp' line

sub import {
    my $package = shift;

    my @exports = grep { "HASH" ne ref($_) } @_;
    my @options = grep { "HASH" eq ref($_) } @_;

    foreach (@options) {
        $Source   = $_->{Source};      # Source name (defaults to script name)
        $LogEvals = $_->{LogEvals};    # Do we log evals when they fail?
        $Register = $_->{Register};    # Should we register the source?
    }

    if ($Register) {
        register_source( $Register, $Source );
    }

    @_ = ( $package, @exports );
    goto &Exporter::import;
}

sub register_source

  # If the Win32::EventLog::Message module is available, register the source
  # with the Windows NT event log (this only works if the user has the proper
  # permissions). This removes the 'description not found' warning in when
  # looking at the event in the event log viewer.

  # Needs to check if a log is created, and if so, close it and then reopen it.

{
    my ( $log_name, $source_name ) = @_;

    # Really what we need to do is to check if the source is registered
    # first...

    my $aux = $LogEvals;
    $LogEvals = 0;    # save LogEvals
    eval {
        require Win32::EventLog::Message;
        import Win32::EventLog::Message;
        Win32::EventLog::Message::RegisterSource( $log_name, $source_name );
    };
    $LogEvals = $aux;    # restore LogEvals

    if ($@) {
        CORE::warn
          "Unable to register source \`$source_name\' in \`$log_name\' log";
    }
}

sub _report

  # Reports an event in the Windows NT event log.

{
    unless ($EventLogHandle) {

        # Create a handle to the Windows NT event log (we do this in the BEGIN
        # block so that we can trap some compilation errors).

        my $log = ($Register) ? $Source : "Application";

        $EventLogHandle = Win32::EventLog->new( $log, Win32::NodeName )
          or CORE::die "Unable to initialize Windows NT event log";

    }

    # If for some reason the log isn't initialized...!

    unless ( defined $EventLogHandle ) {
        CORE::die "Win32::EventLog not initialized in Win32::EventLog::Carp";
        return;
    }

    my ( $event_type, $event_text ) = @_;

    unless ( ( defined $event_text ) && ( defined $event_type ) ) {
        return;
    }

    # If we're posting to the security log, convert the event types to
    # ones associated with the security log. (In reality, Windows
    # doesn't seem to care, but we want to play nice...)

    if ( ( $Register || "" ) eq "Security" ) {
        if ( $event_type == EVENTLOG_INFORMATION_TYPE ) {
            $event_type = EVENTLOG_AUDIT_SUCCESS;
        }
        else {
            $event_type = EVENTLOG_AUDIT_FAILURE;
        }
    }

    # Change newlines to semicolons ('; ') since they do not show up well in
    # the event log viewer (does Windows 2000 handle newlines better?)

    $event_text = join( ": ", $SourceFileName, $event_text );

    #     $event_text =~ s/\x0/; /g;                # only one string is used
    $event_text =~ s/(\r?\n){1,}(?!\z)/\; /g;
    $event_text =~ s/\r?\n\z//;

    my $event = {
        Computer  => Win32::NodeName,
        Source    => $Source,
        EventID   => 0,
        Category  => 0,
        EventType => $event_type,
        Strings   => $event_text,
        Data      => "",
    };

    $EventLogHandle->Report($event);
}

# Test to see if we're in an eval { }

sub _ineval {
    if ($LogEvals)    # If $LogEvals is true, lie and say we're never in an eval
    {
        return;
    }
    else              # Otherwise actually do a test
    {

        # This test is based on the one used in CGI::Carp v1.20
        return ( Carp::longmess(@_) =~ /eval [\'\{]/m );
    }
}

# Our own verson of "warn"

sub _warn {
    _report( EVENTLOG_WARNING_TYPE, @_ );
    CORE::warn @_;
}

# Our own version of "die"

sub _die {
    unless ( _ineval @_ )    # don't log it if we're in an eval
    {
        _report( EVENTLOG_ERROR_TYPE, @_ );
    }
    CORE::die @_;
}

BEGIN {

    # These are hooks for defining our own Source and Log

    $SourceFileName = File::Spec->rel2abs($0);

    unless ($Source) {

        # We use the basename of the file because registry keys cannot have
        # slashes in them. Of course since we are registering an event source
        # (only if we have admin privs) we'll include the full patch in the
        # event text (after all, an error in 'index.pl' doesn't tell us which
        # one).

        $Source = File::Basename::basename($SourceFileName);
    }

    # If there's already a handler, we just report the error to the log and
    # go to the existing handler (so we assume the other handler does what
    # it should); otherwise we use our own.

    if ( $SIG{__WARN__} ) {
        my $previous = $SIG{__WARN__};
        $SIG{__WARN__} = sub {
            _report( EVENTLOG_WARNING_TYPE, @_ );
            return &$previous;
        };
    }
    else {
        $SIG{__WARN__} = \&Win32::EventLog::Carp::_warn;
    }

    # Likewise for "die", we put ourselves between an existing signal handler
    # rather than take it over.

    if ( $SIG{__DIE__} ) {
        my $previous = $SIG{__DIE__};
        $SIG{__DIE__} = sub {
            unless ( _ineval(@_) ) {
                _report( EVENTLOG_ERROR_TYPE, @_ );
            }
            return &$previous;
        };
    }
    else {
        $SIG{__DIE__} = \&Win32::EventLog::Carp::_die;
    }

}

# Close the event log.

sub _closelog() {
    if ($EventLogHandle) {
        $EventLogHandle->Close();
        $EventLogHandle = undef;
    }
}

END {

    # Make sure we clean up after ourselves!
    _closelog();
}

# Our own versions of Carp's functions ... we piggyback on Carp's special
# "longmess" and shortmess" functions. (According to some discussion on
# the Perl 5 Porters list in July 2001 these may be renamed to "yodel" and
# "yelp", but with aliases for the old names. Don't panic.)

sub carp    { CORE::warn Carp::shortmess @_; }
sub croak   { CORE::die Carp::shortmess @_; }
sub cluck   { CORE::warn Carp::longmess @_; }
sub confess { CORE::die Carp::longmess @_; }

# Since posting diagnostic (non-warning/error) messages into the event log
# is useful, why not a function that simply reports to the log and STDERR
# without being considered an error? Hence, "click".

sub click {
    my $message = Carp::shortmess(@_);
    &_report( EVENTLOG_INFORMATION_TYPE, $message );
    print STDERR $message;
}

1;
__END__

=head1 NAME

Win32::EventLog::Carp - for carping in the Windows NT Event Log

=head1 BERSION

This document describes version 1.41 of Win32::EventLog::Carp, released
2007-05-19.

=head1 REQUIREMENTS

  Carp
  Win32::EventLog

These should be standard modules on Win32 systems.

The module will use C<Win32::EventLog::Message> to register itself as a
source, if that module is installed.

=head1 SYNOPSIS

  use Win32::EventLog::Carp;
  croak "We're outta here!";

  use Win32::EventLog::Carp qw(cluck);
  cluck "This is how we got here!";

=head1 DESCRIPTION

C<Win32::EventLog::Carp> traps warnings and fatal errors in Perl and reports
these errors in the Windows NT Event Log. This is useful for scripts which
run as services or through the scheduler, and for CGI/ISAPI scripts.

The interface is similar to L<Carp>: the C<carp>, C<croak> and C<confess>
functions are exported (with C<cluck> being optional).  You need only change
references of "Carp" to "Win32::EventLog::Carp" to begin using this module.

One notable exception is the addition of the C<click> function:

  Win32::EventLog::Carp::click "Hello!\n";

This outouts a message to F<STDERR> with a short stack trace and allows scripts
to post a simple "I have started" or "I am doing XYZ now" message to the log.
To avoid the stack trace, end the message with a newline (which is what
happens with the C<Carp> module).

=head2 FUNCTIONS

=over 4

=item carp

=item cluck

=item confess

=item croak

See the documentation to the C<Carp> module for an explanation of these routines.
The only difference is that instead of sending their output to STDERR, the message
is also logged in the Application Log.

=item click

Similar to C<cluck>, except that it prints to STDERR directly, rather
than going through Carp.

=item register_source

If the Win32::EventLog::Message module is available, register the source
with the Windows NT event log (this only works if the user has the proper
permissions). This removes the 'description not found' warning in when
looking at the event in the event log viewer.

=back

=head2 Using Win32::EventLog::Carp with CGI::Carp

Some modules which trap the C<__WARN__> and C<__DIE__> signals are not very
friendly, and will cancel out existing traps. The solution is to use this
module I<after> using other modules:

  use CGI::Carp;
  use Win32::EventLog::Carp

or

  BEGIN
    {
      $SIG{__WARN__} = \&my_handler;
    }

  use Win32::EventLog::Carp

It is assumed that the previous handler will properly C<warn> or C<die> as
appropriate. This module will instead report these events to the NT event
log.

=head2 Logging failed evals

By default, this module will no longer log errors in the event log when
something dies in an eval. If you would like to enable this, specify the
C<LogEvals> option:

  use Win32::EventLog::Carp
        {
          LogEvals => 1
        };

You can also change the value from within your program:

  $Win32::EventLog::Carp::LogEvals = 1;

=head2 Event Source Registration

If the C<Win32::EventLog::Message> module is installed on the system, I<and if
the script is run with the appropriate (Administrator) permissions>, then
Perl program will attempt register itself as an event source. Which means
that

  carp "Hello";

will produce something like

  Hello at script.pl line 10

rather than

  The description for Event ID ( 0 ) in Source ( script.pl ) could
  not be found. It contains the following insertion string(s): Hello
  at script.pl line 10.

=head2 Redefining Event Sources

You can specify a different event source. The following

  use Win32::EventLog::Carp qw(cluck carp croak click confess),
        {
          Source => 'MyProject'
        };

will list the source as "MyProject" rather than the filename.

=head2 Logging to Security or System Logs

You can specify a log other than the Application Log to report events
to:

  use Win32::EventLog::Carp 1.40
        {
          Register => 'System'
        };

Events can only be posted to one log.  (For example, you cannot have
some events go to the Application Log while others go to the Security
Log.)

Once you have registered a source to an event log, it may not be
possible to register it to a different log.

This feature should still be considered experimental.

=head2 Forcing a Stack Trace

As with C<Carp>, you can force a stack trace by specifying the C<verbose>
option:

  perl -MCarp=verbose script.pl

=head2 Windows 95/98/ME

Windows 95/98/ME do not support the event log, so this module will not
work on those operating systems.  If you are writing scripts which
will be used on both NT-based and non-NT-based operating systems, use
the following workaround:

  require Win32;

  if (Win32::IsWinNT) {
    require Win32::EventLog::Carp;
    import Win32::EventLog::Carp 1.31;
  }
  else {
    require Carp;
    import Carp;
  }

This will import the standard C<Carp> namespace for both types of
machines, although the C<click> function will not be available to
Windows 95/98/ME scripts.

=head1 KNOWN ISSUES

See L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Win32-EventLog-Carp>
for an up-to-date list of known issues and bugs.

=head2 Basename of Event Source

We use the basename of the script as the event source, rather than the full
pathname. This allows us to register the source name (since we cannot have
slashes in registered event log source names).

The downside is that we have to view the event text to see which
script it is (for common script names in a web site, for instance).
In such cases, define a custom source name related to the application.

=head2 IIS and Windows Server 2003

In some server configurations using IIS (Windows Server 2003), you may
need to set security policy to grant permissions to write to the event
log(s).

See Microsoft KnowledgeBase Article 323076 at
L<http://support.microsoft.com/default.aspx?scid=kb;en-us;323076>.

=head2 Test::Exception and Test::Warn

When using L<Test::Exception> functions such as C<dies_ok>, the source
will be listed as the "Test::Exception" module rather than the script
that is running the tests.

L<Test::Warn> functions will block warnings from being posted to the
event log altogether.

=head1 SEE ALSO

  Carp
  Win32::EventLog
  Win32::EventLog::Message

C<Win32::EventLog::Message> can be found at
L<http://www.roth.net/perl/packages/>

A PowerPoint presentation about this module can be found at
L<http://stonybrook.pm.org/>

=head2 Related Modules

  CGI::Carp
  Log::Dispatch::Win32EventLog
  Tk::Carp
  Win32::GUI::Carp
  Wx::Perl::Carp

=head1 AUTHOR

David Landgren <dland at cpan.org> (current maintainer)

Robert Rothenberg <rrwo at cpan.org>

=head2 Suggestions and Bug Reporting

Feedback is always welcome.  Please use the CPAN Request Tracker at
L<http://rt.cpan.org> to submit bug reports.

=head1 LICENSE

Copyright (c) 2000-2004, Robert Rothenberg. Copyright (c) 2006,
David Landgren. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
