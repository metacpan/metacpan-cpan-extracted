#!/usr/bin/perl -w

#==============================================================================
# description:
#------------------------------------------------------------------------------
# A simple Perl script to test the perl-Hardware-UPS-Perl distribution.
# The following tests are included so far:
#
#   - setting up a logger with output on STDERR
#   - setting up a PID file
#   - initializing a connection object
#   - initializing a driver object
#
#==============================================================================

#==============================================================================
# Entries for revision control:
#------------------------------------------------------------------------------
# Revision        : $Revision: 1.1 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/17 19:48:21 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
# $Log: simple.t,v $
# Revision 1.1  2007/04/17 19:48:21  creile
# initial revision.
#
#
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   Test::Simple                    - Basic utilities for writing tests
#   vars                            - Perl pragma to predeclare global variable
#                                     names
#
#   Hardware::UPS::Perl::Connection - importing Hardware::UPS::Perl connection
#   Hardware::UPS::Perl::Constants  - importing Hardware::UPS::Perl constants
#   Hardware::UPS::Perl::Driver     - importing Hardware::UPS::Perl driver
#   Hardware::UPS::Perl::Logging    - importing Hardware::UPS::Perl methods
#                                     dealing with log files
#   Hardware::UPS::Perl::PID        - importing Hardware::UPS::Perl methods
#                                     dealing with PID files
#
#==============================================================================

use Test::Simple tests => 4;

use Hardware::UPS::Perl::Connection;
use Hardware::UPS::Perl::Constants qw(
   UPSSCRIPT
);
use Hardware::UPS::Perl::Driver;
use Hardware::UPS::Perl::Logging;
use Hardware::UPS::Perl::PID;

#==============================================================================
# defining global variables:
#------------------------------------------------------------------------------
#
#   $Package                - the package to test
#   $Logger                 - the UPS logging object
#   $Connection             - the connection object
#   $Driver                 - the driver object
#   $Pid                    - the PID file object
#
#==============================================================================

use vars qw(
   $Package
   $Logger
   $Pid
   $Connection
   $Driver
);

#==============================================================================
# defining subroutines:
#==============================================================================

sub Check {

    # subroutine to check the reference created
    #
    # parameters: $ref     (input) - the reference
    #             $package (input) - the package the reference belongs to

    # input as hidden local variables:
    my $ref     = shift;
    my $package = shift;

    return defined($ref) and (ref($ref) eq $package);

} # end of subdourine "Check"

#==============================================================================
# start of main body:
#==============================================================================
#
# testing the logger
#
$Package    = 'Hardware::UPS::Perl::Logging';
$Logger     = Hardware::UPS::Perl::Logging->new();

ok( Check($Logger, $Package), "$Package\->new() works" );

#
# testing the OO pid
#
$Package    = 'Hardware::UPS::Perl::PID';
$PID        = Hardware::UPS::Perl::PID->new({
   PIDFile  => "/tmp/${\(UPSSCRIPT)}.pid",
   Logger   => $Logger,
});

ok( Check($PID, $Package), "$Package\->new() works" );

#
# testing setting up a connection
#
$Package    = 'Hardware::UPS::Perl::Connection';
$Connection = Hardware::UPS::Perl::Connection->new({
   Logger   => $Logger
});

ok( Check($Connection, $Package), "$Package\->new() works");

#
# testing setting up a driver
#
$Package    = 'Hardware::UPS::Perl::Driver';
$Driver     = Hardware::UPS::Perl::Driver->new({
   Logger   => $Logger
});

ok( Check($Driver, $Package), "$Package\->new() works" );

# exiting
exit 0
