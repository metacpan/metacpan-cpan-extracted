package Hardware::UPS::Perl::Driver;

#==============================================================================
# package description:
#==============================================================================
# This package supplies a set of methods to load an UPS driver. For a detailed
# description see the pod documentation included at the end of this file.
#
# List of public methods:
# -----------------------
#   new                     - initializing a Hardware::UPS::Perl::Driver object
#   setLogger               - setting the current logger
#   getLogger               - getting the current logger
#   setDriverOptions        - setting the UPS driver options
#   getDriverOptions        - getting the current UPS driver options
#   setDriverHandle         - setting the UPS driver handle
#   getDriverHandle         - getting the current UPS driver handle
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
# Revision        : $Revision: 1.8 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/17 19:45:29 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
#   $Log: Driver.pm,v $
#   Revision 1.8  2007/04/17 19:45:29  creile
#   missing import Hardware::UPS::Perl::Logging added.
#
#   Revision 1.7  2007/04/14 09:37:26  creile
#   documentation update.
#
#   Revision 1.6  2007/04/07 15:14:21  creile
#   adaptations to "best practices" style;
#   update of documentation.
#
#   Revision 1.5  2007/03/13 17:19:06  creile
#   options as anonymous hashes.
#
#   Revision 1.4  2007/03/03 21:20:23  creile
#   new variable $UPSERROR added;
#   "return undef" replaced by "return";
#   adaptations to new Constants.pm.
#
#   Revision 1.3  2007/02/25 17:04:56  creile
#   methods setDriver() and getDriver renamed to
#   setDriverHandle() and getDriverHandle();
#   option handling redesigned.
#
#   Revision 1.2  2007/02/05 20:35:09  creile
#   pod documentation revised.
#
#   Revision 1.1  2007/02/04 18:23:50  creile
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

    $VERSION = sprintf( "%d.%02d", q$Revision: 1.8 $ =~ /(\d+)\.(\d+)/ );

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

    # public method to construct a driver object
    #
    # parameters: $class   (input) - class
    #             $options (input) - anonymous hash; options
    #
    # The following option keys are recognized:
    #
    #   Driver  ($) - string; the driver to load; optional
    #   Options ($) - anonymous hash; the options of the driver to load;
    #                 optional
    #   Logger  ($) - Hardware::UPS::Perl::Logging object; the logger to use;
    #                 optional

    # input as hidden local variables
    my $class   = shift;
    my $options = @_ ? shift : {};

    # hidden local variables
    my $self    = {};       # referent to be blessed
    my $refType;            # a reference type
    my $option;             # an option
    my $logger;             # the logger object
    my $driverName;         # the driver name
    my $driverOptions;      # the driver options

    # blessing driver object
    bless $self, $class;

    # checking options
    $refType = ref($options);
    if ($refType ne 'HASH') {
        error("not a hash reference -- <$refType>");
    }

    # the logger; if we don't have one, we have to create our own with output
    # on STDERR
    $logger = delete $options->{Logger};

    if (!defined $logger) {
        $logger = Hardware::UPS::Perl::Logging->new()
            or return;
    }

    # the driver name
    $driverName    = delete $options->{Driver};

    # the driver options
    $driverOptions = delete $options->{Options};

    if (defined $driverOptions) {
        $refType = ref($driverOptions);
        if ($refType ne 'HASH') {
            error("no hash reference -- <$refType>");
        }
    } else {
        $driverOptions = {};
    }

    # checking for misspelled options
    foreach $option (keys %{$options}) {
        error("option unknown -- $option");
    }

    # initializing
    #
    # the error message
    $self->{errorMessage} = q{};

    # the logger
    $self->setLogger($logger);

    # setting the driver
    $self->setDriverOptions($driverOptions);

    if (defined $driverName) {
        $self->setDriverHandle($driverName)
            or  do {
                    $UPSERROR = $self->getErrorMessage();
                    return;
                };
    }

    # returning blessed driver object
    return $self;

} # end of public method "new"

sub DESTROY {

    # the destructor will do nothing, actually

} # end of the destructor

sub getErrorMessage {

    # public method to get the current error message
    #
    # parameters: $self (input) - referent to a driver object

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
    # parameters: $self (input) - referent to a driver object

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
    # parameters: $self   (input) - referent to a driver object
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

sub getDriverOptions {

    # public method to get the options of the driver
    #
    # parameters: $self (input) - referent to a driver object

    # input as hidden local variable
    my $self = shift;

    # getting driver options
    if (exists $self->{options}) {
        return $self->{options};
    } else {
        return;
    }

} # end of public method "getDriverOptions"

sub setDriverOptions {

    # public method to set the options for the UPS driver to load
    #
    # parameters: $self    (input) - referent to a driver object
    #             $options (input) - anonymous array; the driver options

    # input as hidden local variables
    my $self    = shift;

    ( (1 == @_) and (ref($_[0]) eq 'HASH'))
        or error("usage: setDriverOptions(\%options)");

    my $options = shift;

    # getting old driver options
    my $oldDriverOptions = $self->getDriverOptions();

    # setting driver options
    $self->{options} = $options;

    # returning old driver options
    return $oldDriverOptions;

} # end of public method "setDriverOptions"

sub getDriverHandle {

    # public method to get the UPS driver handle
    #
    # parameters: $self (input) - referent to a driver object

    # input as hidden local variable
    my $self = shift;

    # getting driver handle
    if (exists $self->{driver}) {
        return $self->{driver};
    }
    else {
        return;
    }

} # end of public method "getDriverHandle"
    
sub setDriverHandle {

    # public method to load an UPS driver handle
    #
    # parameters: $self   (input) - referent to a driver object
    #             $driver (input) - the driver to load 

    # input as hidden local variables
    my $self = shift;

    (1 == @_) or error("usage: setDriverHandle(driver)");
    my $driver  = shift;

    # hidden local variables
    my $driverClass;        # the driver class
    my $driverHandle;       # the driver handle

    # getting driver class, making allowance for case-insensitivity
    $driverClass = "Hardware::UPS::Perl::Driver::".ucfirst(lc($driver));
    eval qq{
	    use $driverClass;	# load the driver
    };

    # checking eval error
    if ($@) {
        $self->{errorMessage} = "eval failed -- $@";
        return 0;
    }

    # setting up driver object
    $driverHandle = eval {
       $driverClass->new($self->getDriverOptions())
    };

    if (!$driverHandle or !ref($driverHandle) or $@) {
        $self->{errorMessage} = "$driverClass initialisation failed -- $@";
        return 0;
    }

    $self->{driver} = $driverHandle;

    return 1;

} # end of public method "setDriverHandle"

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

Hardware::UPS::Perl::Driver - package of methods to load a Hardware::UPS::Perl
driver.

=head1 SYNOPSIS

    use Hardware::UPS::Perl::Driver;

    $driver = Hardware::UPS::Perl::Driver->new({
        Driver  => Megatec,
        Options => \%options,
        Logger  => $Logger,
    });

    $ups = $driver->getDriverHandle();

    $driver = Hardware::UPS::Perl::Driver->new();

    $driver->setDriverOptions(\@options);
    $driver->setLogger($Logger);
    $driver->setDriverHandle("Megatec");

    $ups = $driver->getDriverHandle();

=head1 DESCRIPTION

B<Hardware::UPS::Perl::Driver> provides methods to load a Hardware::UPS::Perl
driver into the namespace of the calling script.

=head1 LIST OF METHODS

=head2 new

=over 4

=item B<Name:>

new - creates a new driver object

=item B<Synopsis:>

    $driver = Hardware::UPS::Perl::Driver->new();

    $driver = Hardware::UPS::Perl::Driver->new({
        Driver  => $driverName,
        Options => \%driverOptions,
        Logger  => $Logger,
    });

=item B<Description:>

B<new> initializes driver object used to load an existing Hardware::UPS::Perl
driver, i.e. a package below B<Hardware::UPS::Perl::Driver>, into the
namespace of the calling script.

B<new> expects the options as an anonymous hash.

=item B<Arguments:>

=over 4

=item C<< Driver  => $driverName >>

optional; string; the name of the UPS driver to load; the name is
case-insensitive.

=item C<< Options => \%driverOptions >>

optional; anonymous hash; the options passed on to the driver to load.

=item C<< Logger  => $logger >>

optional; a B<Hardware::UPS::Perl::Logging> object; defines a logger; if not
specified, a logger sending its output to F<STDERR> is created.

=back

=item B<See Also:>

L<"getDriverHandle">,
L<"getDriverOptions">,
L<"getLogger">,
L<"setDriverHandle">,
L<"setDriverOptions">,
L<"setLogger">

=back

=head2 setLogger

=over 4

=item B<Name:>

setLogger - sets the logger to use

=item B<Synopsis:>

    $driver = Hardware::UPS::Perl::Driver->new();

    $driver->setLogger($logger);

=item B<Description:>

B<setLogger> sets the logger object used for logging. B<setLogger> returns
the previous logger used.

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

    $driver = Hardware::UPS::Perl::Driver->new();

    $logger = $driver->getLogger();

=item B<Description:>

B<getLogger> returns the current logger, a B<Hardware::UPS::Perl::Logging>
object used for logging, if defined, undef otherwise.

=item B<See Also:>

L<"new">,
L<"setLogger">

=back

=head2 setDriverOptions

=over 4

=item B<Name:>

setDriverOptions - sets the driver options for a new driver

=item B<Synopsis:>

    $driver = Hardware::UPS::Perl::Driver->new();

    $driver->setDriverOptions(\%driverOptions);

=item B<Description:>

B<setDriverOptions> sets the options of the driver. B<setDriveroptions>
returns an anonymous hash of the driver options previously used. The driver
options are not promoted to the current driver so far.

=item B<Arguments:>

=over 4

=item C<\%driverOptions>

required; an anonymous hash; defines the options used to create a new driver
object.

=back

=item B<See Also:>

L<"new">,
L<"getDriverHandle">,
L<"getDriverOptions">,
L<"setDriverHandle">

=back

=head2 getDriverOptions

=over 4

=item B<Name:>

getDriverOptions - gets the driver options for a new driver

=item B<Synopsis:>

    $driver = Hardware::UPS::Perl::Driver->new();

    $driver->getDriverOptions();

=item B<Description:>

B<getDriverOptions> returns the options, an anonymous hash, currently used
for the driver.

=item B<See Also:>

L<"new">,
L<"getDriverHandle">,
L<"setDriverHandle">,
L<"setDriverOptions">

=back

=head2 setDriverHandle

=over 4

=item B<Name:>

setDriverHandle - sets the UPS driver handle

=item B<Synopsis:>

    $driver = Hardware::UPS::Perl::Driver->new();

    $driver->setDriverOptions(\%driverOptions);
    $driver->setDriverHandle("Megatec");

=item B<Description:>

B<setDriverHandle> sets the UPS driver handle, i.e. defines the driver package
below F<Hardware::UPS::Perl::Driver>. It returns 1 on success, and 0, if
something went wrong setting the internal error message.

=item B<Arguments:>

=over 4

=item C<$driver>

required; string; the case-insensitive name of the UPS driver, i.e. it defines
the driver package F<Hardware::UPS::Perl::Driver::C<$driver>> to use to deal
with the UPS.

=back

=item B<See Also:>

L<"new">,
L<"getDriverHandle">,
L<"getDriverOptions">,
L<"getErrorMessage">

=back

=head2 getDriverHandle

=over 4

=item B<Name:>

getDriverHandle - gets the UPS driver handle

=item B<Synopsis:>

    $driver = Hardware::UPS::Perl::Driver->new();

    $driver->setDriverOptions(\@driverOptions);
    $driver->setDriverHandle("Megatec");

    # a Hardware::UPS::Perl:Driver::Megatec object
    $ups = $driver->getDriverHandle();


    $driver = Hardware::UPS::Perl::Driver->new({
        Driver  => "Megatec",
        Options => \%driverOptions,
    });

    # a Hardware::UPS::Perl:Driver::Megatec object
    $ups = $driver->getDriverHandle();

=item B<Description:>

B<getDriver> returns the current UPS driver handle, i.e. it loads the object
required to deal with the UPS into the namespace of the calling script.

=item B<See Also:>

L<"new">,
L<"getDriverOptions">,
L<"setDriverHandle">,
L<"setDriverOptions">

=back

=head2 getErrorMessage

=over 4

=item B<Name:>

getErrorMessage - gets the internal error message

=item B<Synopsis:>

    $driver = Hardware::UPS::Perl::Driver->new();

    unless ($driver->setDriver("Megatec")) {
        print STDERR $driver->getErrorMessage(), "\n";
        exit 1;
    }

=item B<Description:>

B<getErrorMessage> returns the internal error message, if something went
wrong.

=back

=head1 SEE ALSO

Hardware::UPS::Perl::Connection(3pm),
Hardware::UPS::Perl::Connection::Net(3pm),
Hardware::UPS::Perl::Connection::Serial(3pm),
Hardware::UPS::Perl::Constants(3pm),
Hardware::UPS::Perl::Driver::Megatec(3pm),
Hardware::UPS::Perl::General(3pm),
Hardware::UPS::Perl::Logging(3pm),
Hardware::UPS::Perl::PID(3pm),
Hardware::UPS::Perl::Utils(3pm) 

=head1 NOTES

B<Hardware::UPS::Perl::Driver> was inspired by the Perl5 extension package
B<DBI>.

Another great resource was the B<Network UPS Tools> site, which can be found
at

    http://www.networkupstools.org

B<Hardware::UPS::Perl::Driver> was developed using B<perl 5.8.8> on a B<SuSE
10.1> Linux distribution.

=head1 BUGS

There are plenty of them for sure. Maybe the embedded pod documentation has to
be revised a little bit.

Suggestions to improve B<Hardware::UPS::Perl::Driver> are welcome, though due
to the lack of time it might take a while to incorporate them.

=head1 AUTHOR

Copyright (c) 2007 by Christian Reile, E<lt>Christian.Reile@t-online.deE<gt>.
All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. For further licensing
details, please see the file COPYING in the distribution.

=cut
