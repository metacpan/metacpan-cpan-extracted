package Hardware::UPS::Perl::Connection;

#==============================================================================
# package description:
#==============================================================================
# This package supplies a set of methods to load a connection. For a detailed
# description see the pod documentation included at the end of this file.
#
# List of public methods:
# -----------------------
#   new                     - initializing a Hardware::UPS::Perl::Connection
#                             object
#   setLogger               - setting the current logger
#   getLogger               - getting the current logger
#   setConnectionOptions    - setting the connection options
#   getConnectionOptions    - getting the connection options
#   setConnectionHandle     - setting the connection handle
#   getConnectionHandle     - getting the current connection handle
#   getErrorMessage         - getting internal error messages
#
#==============================================================================

#==============================================================================
# Copyright:
#==============================================================================
# Copyright (c) 2007 Christian Reile, <Christian.Reile@t-online.de>. All
# rights reserved. This program is free software; you can redistribute it
# and/or modify it under the same terms as Perl itself.
#==============================================================================

#==============================================================================
# Entries for Revision Control:
#==============================================================================
# Revision        : $Revision: 1.6 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/17 19:45:01 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
#   $Log: Connection.pm,v $
#   Revision 1.6  2007/04/17 19:45:01  creile
#   missing import of Hardware::UPS::Perl::Logging added.
#
#   Revision 1.5  2007/04/14 09:37:26  creile
#   documentation update.
#
#   Revision 1.4  2007/04/07 15:13:24  creile
#   adaptations to "best practices" style;
#   update of documentation.
#
#   Revision 1.3  2007/03/13 17:17:23  creile
#   options as anonymous hashes;
#   reconnect fix.
#
#   Revision 1.2  2007/03/03 21:22:45  creile
#   new variable $UPSERROR added;
#   "return undef" replaced by "return";
#   adaptations to new Constants.pm;
#   option "Connection" of method new() changed to "Type".
#
#   Revision 1.1  2007/02/25 17:02:44  creile
#   initial revision.
#
#
#==============================================================================

#==============================================================================
# module preamble:
#==============================================================================

use strict;

BEGIN {
    
    use vars qw($VERSION @ISA);

    $VERSION = sprintf( "%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/ );

    @ISA     = qw();

}

#==============================================================================
# end of module preamble
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   Hardware::UPS::Perl::General    - importing Hardware::UPS::Perl variables
#                                     and functions for scripts
#   Hardware::UPS::Perl::Logging    - importing Hardware::UPS::Perl methods
#                                     dealing with logfiles
#   Hardware::UPS::Perl::Utils      - importing Hardware::UPS::Perl utility
#                                     functions for packages
#
#==============================================================================

use Hardware::UPS::Perl::General qw(
    $UPSERROR
);
use Hardware::UPS::Perl::Logging;
use Hardware::UPS::Perl::Utils qw(
    error
);

#==============================================================================
# public methods:
#==============================================================================

sub new {

    # public method to construct a connection object
    #
    # parameters: $class   (input) - class
    #             $options (input) - anonymous hash; options
    #
    # The following option keys are recognized:
    #
    #   Type    ($)  - string; the connection type to load; optional;
    #   Options ($)  - anonymous array; the options of the connection to
    #                  load; optional;
    #   Logger  ($)  - Hardware::UPS::Perl::Logging object; the logger to
    #                  use; optional.

    # input as hidden local variables
    my $class   = shift;
    my $options = @_ ? shift : {};

    # hidden local variables
    my $self  = {};         # referent to be blessed
    my $option;             # an option
    my $refType;            # a reference type
    my $logger;             # the logger object
    my $connectionType;     # the connection type
    my $connectionOptions;  # the connection options

    # blessing connection object
    bless $self, $class;

    # checking options
    $refType = ref($options);
    if ($refType ne 'HASH') {
        error("not a hash reference -- <$refType>");
    }

    # the logger; if we don't have one, we have to create our own with output
    # on STDERR
    $logger = delete $options->{Logger};

    unless (defined $logger) {
        $logger = Hardware::UPS::Perl::Logging->new()
            or return;
    }

    $self->setLogger($logger);

    # the connection options
    $connectionOptions = delete $options->{Options};

    if (defined $connectionOptions) {
        $refType = ref($connectionOptions);
        if ($refType ne 'HASH') {
            error("no hash reference -- <$refType>");
        }
    }
    else {
        $connectionOptions = {};
    }

    # the connection type
    $connectionType = delete $options->{Type};

    # checking for misspelled options
    foreach $option (keys %{$options}) {
        error("option unknown -- $option");
    }

    # initializing the error message
    $self->{errorMessage} = q{};

    # setting the connection
    $self->setConnectionOptions($connectionOptions);

    if (defined $connectionType) {
        $self->setConnectionHandle($connectionType)
            or  do {
                    $UPSERROR = $self->getErrorMessage();
                    return;
                };
    }

    # returning blessed connection object
    return $self;

} # end of public method "new"

sub DESTROY {

    # the destructor will do nothing, actually

} # end of the destructor

sub getErrorMessage {

    # public method to get the current error message
    #
    # parameters: $self (input) - referent to a connection object

    # input as hidden local variable
    my $self = shift;

    # getting the error message
    if (exists $self->{errorMessage}) {
        return $self->{errorMessage};
    }
    else {
        return;
    }

} # end of public method "getErrorMessage"

sub getLogger {

    # public method to get the logger
    #
    # parameters: $self (input) - referent to a connection object

    # input as hidden local variable
    my $self = shift;

    # getting logger
    if (exists $self->{logger}) {
        return $self->{logger};
    }
    else {
        return;
    }

} # end of public method "getLogger"

sub setLogger {

    # public method to set the logger
    #
    # parameters: $self   (input) - referent to a connection object
    #             $logger (input) - the logging object

    # input as hidden local variables
    my $self   = shift;

    1 == @_ or error("usage: setLogger(LOGGER)");
    my $logger = shift;

    if (defined $logger) {
        my $loggerRefType = ref($logger);
        if ($loggerRefType ne 'Hardware::UPS::Perl::Logging') {
            error("no logger -- <$loggerRefType>");
        }
    }

    # getting old logger
    my $oldLogger = $self->getLogger();

    # setting the logger
    $self->{logger} = $logger;

    # returning old logger
    return $oldLogger;

} # end of public method "setLogger"

sub getConnectionOptions {

    # public method to get the options of the connection
    #
    # parameters: $self (input) - referent to a connection object

    # input as hidden local variable
    my $self = shift;

    # getting connection options
    if (exists $self->{options}) {
        return $self->{options};
    }
    else {
        return;
    }

} # end of public method "getConnectionOptions"

sub setConnectionOptions {

    # public method to set the options for connection to load
    #
    # parameters: $self    (input) - referent to a connection object
    #             $options (input) - anonymous hash; the connection options

    # input as hidden local variables
    my $self    = shift;

    ( (1 == @_) and (ref($_[0]) eq 'HASH'))
        or error("usage: setConnectionOptions(\%options)");

    my $options = shift;

    # getting old connection options
    my $oldConnectionOptions = $self->getConnectionOptions();

    # setting connection options
    $self->{options} = $options;

    # returning old connection option
    return $oldConnectionOptions;

} # end of public method "setConnectionOptions"

sub getConnectionHandle {

    # public method to get the connection handle
    #
    # parameters: $self (input) - referent to a connection object

    # input as hidden local variable
    my $self = shift;

    # getting connection handle
    if (exists $self->{connection}) {
        return $self->{connection};
    }
    else {
        return;
    }

} # end of public method "getConnectionHandle"
    
sub setConnectionHandle {

    # public method to load the connection handle
    #
    # parameters: $self       (input) - referent to a connection object
    #             $connection (input) - string; the name of the connection to
    #                                   load 

    # input as hidden local variables
    my $self       = shift;

    (1 == @_) or error("usage: setConnectionHandle(connection)");
    my $connection = shift;

    # hidden local variables
    my $connectionClass;    # the connection class
    my $connectionHandle;   # the connection handle

    # getting connection class, making allowance for case-insensitivity
    $connectionClass =
        "Hardware::UPS::Perl::Connection::".ucfirst(lc($connection));
    eval qq{
	    use $connectionClass;	# load the connection
    };

    # checking eval error
    if ($@) {
        $self->{errorMessage} = "eval failed -- $@";
        return 0;
    }

    # setting up connection object
    $connectionHandle = eval {
       $connectionClass->new($self->getConnectionOptions())
    };

    if (!$connectionHandle or !ref($connectionHandle) or $@) {
        $self->{errorMessage} = "$connectionClass initialisation failed -- $@";
        return 0;
    }

    $self->{connection} = $connectionHandle;

    return 1;

} # end of public method "setConnectionHandle"

sub connect {

    # public method to connect to an UPA agent or the serial port an UPS
    # resides
    #
    # parameters: $self (input) - referent to a connection object

    # input as hidden local variable
    my $self = shift;

    # getting connection handle
    my $connectionHandle = $self->getConnectionHandle();
    if (!$connectionHandle->connect(@_)) {
        $self->{errorMessage}
            = "connection failed -- ".$connectionHandle->getErrorMessage();
        return 0;
    }

    return 1;

} # end of public method "connect"

sub connected {

    # public method to test the connection status
    #
    # parameters: $self (input) - referent to a connection object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $connectionHandle;   # the connection

    # checking for connection
    $connectionHandle = $self->getConnectionHandle();
    if (defined $connectionHandle) {
        return $connectionHandle->connected();
    }
    else {
        return 0;
    }

} # end of public method "connected"

sub disconnect {

    # public method to disconnect from an UPS agent or the serial
    # port a local UPS resides
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # deleting connection if connected
    if ($self->connected()) {

        # deleting connection
        $self->getConnectionHandle()->disconnect();

        return 1;

    }
    else {

        # error: UPS was not connected
        $self->{errorMessage} = "not connected to UPS";

        return 0;
    }

} # end of public method "disconnect"

sub sendCommand {

    # public method to send a command to the UPS and getting its response
    #
    # parameters: $self         (input) - referent to an UPS object
    #             $command      (input) - command sent to UPS
    #             $response     (input) - response from UPS (anonymous reference)
    #             $responseSize (input) - size of response from UPS

    # input as hidden local variable
    my $self         = shift;
    my $command      = shift;
    my $response     = shift;
    my $responseSize = shift;

    # hidden local variables
    my $connectionHandle;   # the connection

    # getting connection
    $connectionHandle = $self->getConnectionHandle();
    unless (defined $connectionHandle) {
        $self->{errorMessage} = "no connection handle available";
        return 0;
    }

    # send message to UPS
    if ($connectionHandle->sendCommand($command, $response, $responseSize)) {
        return 1;
    }
    else {
        $self->{errorMessage} = $connectionHandle->getErrorMessage();
        return 0;
    }

} # end of public method "sendCommand"

#==============================================================================
# package return:
#==============================================================================
1;

__END__

#==============================================================================
# embedded pod documentation:
#==============================================================================

=pod

=head1 NAME

Hardware::UPS::Perl::Connection - package of methods to load a
Hardware::UPS::Perl connection.

=head1 SYNOPSIS

    use Hardware::UPS::Perl::Connection;

    $connection = Hardware::UPS::Perl::Connection->new({
        Type    => "serial",
        Options => \%options,
        Logger  => $Logger,
    });

    $connectionHandle = $connection->getConnectionHandle();

    $connection = Hardware::UPS::Perl::Connection->new();

    $connection->setConnectionOptions(\%options);
    $connection->setLogger($Logger);
    $connection->setConnectionHandle("serial");

    $connectionHandle = $connection->getConnectionHandle();

=head1 DESCRIPTION

B<Hardware::UPS::Perl::Connection> provides methods to load a
Hardware::UPS::Perl connection into the namespace of the calling script.

=head1 LIST OF METHODS

=head2 new

=over 4

=item B<Name:>

new - creates a new connection object

=item B<Synopsis:>

    $connection = Hardware::UPS::Perl::Connection->new();

    $connection = Hardware::UPS::Perl::Connection->new({
        Type    => $connectionType,
        Options => \%connectionOptions,
        Logger  => $Logger,
    });

=item B<Description:>

B<new> initializes connection object used to load an existing
Hardware::UPS::Perl connection, i.e. a package below
B<Hardware::UPS::Perl::Connection>, into the namespace of the calling script.

B<new> expects the options as an anonymous hash.

=item B<Arguments:>

=over 4

=item C<< Type  => $connectionType >>

optional; string; the connection type to load; the type is
case-insensitive.

=item C<< Options => \%connectionOptions >>

optional; anonymous hash; the options passed on to the connection to load.

=item C<< Logger  => $logger >>

optional; a B<Hardware::UPS::Perl::Logging> object; defines a logger; if not
specified, a logger sending its output to F<STDERR> is created.

=back

=item B<See Also:>

L<"getConnectionHandle">,
L<"getConnectionOptions">,
L<"getLogger">,
L<"setConnectionHandle">,
L<"setConnectionOptions">,
L<"setLogger">

=back

=head2 setLogger

=over 4

=item B<Name:>

setLogger - sets the logger to use

=item B<Synopsis:>

    $connection = Hardware::UPS::Perl::Connection->new();

    $connection->setLogger($logger);

=item B<Description:>

B<setLogger> sets the logger, i.e. a B<Hardware::UPS::Perl::Logging> object
used for logging. B<setLogger> returns the previous logger used.

=item B<Arguments:>

=over 4

=item C<$logger>

required; a B<Hardware::UPS::Perl:Logging> object; defines the logger for
logging.

=back

=item B<See Also:>

L<"new">,
L<"getLogger">

=back

=head2 getLogger

=over 4

=item B<Name:>

getLogger - gets the current logger for logging

=item B<Synopsis:>

    $connection = Hardware::UPS::Perl::Connection->new();

    $logger = $connection->getLogger();

=item B<Description:>

B<getLogger> returns the current logger, a B<Hardware::UPS::Perl::Logging>
object used for logging, if defined, undef otherwise.

=item B<See Also:>

L<"new">,
L<"setLogger">

=back

=head2 setConnectionOptions

=over 4

=item B<Name:>

setConnectionOptions - sets the connection options for a new connection handle

=item B<Synopsis:>

    $connection = Hardware::UPS::Perl::Connection->new();

    $connection->setConnectionOptions(\%connectionOptions);

=item B<Description:>

B<setConnectionOptions> sets the options of the connection.
B<setConnectionoptions> returns an anonymous array of the connection options
previously used. The connection options are not promoted to the current
connection handle so far.

=item B<Arguments:>

=over 4

=item C<\%connectionOptions>

required; an anonymous hash; defines the options used to create a new
connection handle.

=back

=item B<See Also:>

L<"new">,
L<"getConnectionOptions">,
L<"getConnectionHandle">,
L<"setConnectionHandle">

=back

=head2 getConnectionOptions

=over 4

=item B<Name:>

getConnectionOptions - gets the connection options for a new connection handle

=item B<Synopsis:>

    $connection = Hardware::UPS::Perl::Connection->new();

    $connection->getConnectionOptions();

=item B<Description:>

B<getConnectionOptions> returns the options, an anonymous array, currently
used for the connection handle.

=item B<See Also:>

L<"new">,
L<"getConnectionHandle">,
L<"setConnectionHandle">,
L<"setConnectionOptions">

=back

=head2 setConnection

=over 4

=item B<Name:>

setConnectionHandle - sets the connection

=item B<Synopsis:>

    $connection = Hardware::UPS::Perl::Connection->new();

    $connection->setConnectionOptions(\%connectionOptions);
    $connection->setConnectionHandle("Serial");

=item B<Description:>

B<setConnectionHandle> sets the UPS connection, i.e. defines the connection
package below F<Hardware::UPS::Perl::Connection>. It returns 1 on success, and
0, if something went wrong setting the internal error message.

=item B<Arguments:>

=over 4

=item C<$connection>

required; string; the case-insensitive name of the connection, i.e. it defines
the connection package F<Hardware::UPS::Perl::Connection::C<$connection>> to
use to connect to the UPS.

=back

=item B<See Also:>

L<"new">,
L<"getConnectionHandle">,
L<"getConnectionOptions">,
L<"getErrorMessage">

=back

=head2 getConnectionHandle

=over 4

=item B<Name:>

getConnectionHandle - gets the UPS connection

=item B<Synopsis:>

    $connection = Hardware::UPS::Perl::Connection->new();

    $connection->setConnectionOptions(\%connectionOptions);
    $connection->setConnectionHandle("Net");

    # a Hardware::UPS::Perl:Connection::Net object
    $ups = $connection->getConnectionHandle();


    $connection = Hardware::UPS::Perl::Connection->new({
        Connection  => "Serial",
        Options     => \%connectionOptions,
    });

    # a Hardware::UPS::Perl:Connection::Serial object
    $ups = $connection->getConnectionHandle();

=item B<Description:>

B<getConnectionHandle> returns the current UPS connection, i.e. it loads the
object required to coonect to the UPS into the namespace of the calling
script.

=item B<See Also:>

L<"new">,
L<"getConnectionOptions">,
L<"setConnectionHandle">,
L<"setConnectionOptions">

=back

=head2 getErrorMessage

=over 4

=item B<Name:>

getErrorMessage - gets the internal error message

=item B<Synopsis:>

    $connection = Hardware::UPS::Perl::Connection->new();

    if (!$connection->setConnectionHandle("serial")) {
        print STDERR $connection->getErrorMessage(), "\n";
        exit 1;
    }

=item B<Description:>

B<getErrorMessage> returns the internal error message, if something went
wrong.

=back

=head1 SEE ALSO

Hardware::UPS::Perl::Connection::Net(3pm),
Hardware::UPS::Perl::Connection::Serial(3pm),
Hardware::UPS::Perl::Constants(3pm),
Hardware::UPS::Perl::Driver(3pm),
Hardware::UPS::Perl::Driver::Megatec(3pm),
Hardware::UPS::Perl::General(3pm),
Hardware::UPS::Perl::Logging(3pm),
Hardware::UPS::Perl::PID(3pm),
Hardware::UPS::Perl::Utils(3pm) 

=head1 NOTES

B<Hardware::UPS::Perl::Connection> was inspired by the Perl5 extension package
B<DBI>.

Another great resource was the B<Network UPS Tools> site, which can be found
at

    http://www.networkupstools.org

B<Hardware::UPS::Perl::Connection> was developed using B<perl 5.8.8> on a
B<SuSE 10.1> Linux distribution.

=head1 BUGS

There are plenty of them for sure. Maybe the embedded pod documentation has to
be revised a little bit.

Suggestions to improve B<Hardware::UPS::Perl::Connection> are welcome, though
due to the lack of time it might take a while to incorporate them.

=head1 AUTHOR

Copyright (c) 2007 by Christian Reile, E<lt>Christian.Reile@t-online.deE<gt>.
All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. For further licensing
details, please see the file COPYING in the distribution.

=cut
