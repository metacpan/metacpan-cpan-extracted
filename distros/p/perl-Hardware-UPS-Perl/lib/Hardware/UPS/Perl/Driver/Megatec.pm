package Hardware::UPS::Perl::Driver::Megatec;

#==============================================================================
# package description:
#==============================================================================
# This package supplies a set of methods dealing with an UPS using the
# Megatec protocol. This might serve as a template for other UPS drivers. For
# a detailed description see the pod documentation included at the end of this
# file.
#
# List of public methods:
# -----------------------
#   new                     - initializing an UPS object
#   setDebugLevel           - setting the debug level
#   getDebugLevel           - getting the debug level
#   setLogger               - setting the current logger
#   getLogger               - getting the current logger
#   getErrorMessage         - getting the error message
#   connect                 - connecting to UPS
#   connected               - connection status to UPS
#   disconnect              - disconnecting from UPS
#   sendCommand             - sending a command to the UPS
#   flush                   - flushing any buffered input
#   readUPSInfo             - reading the UPS info
#   getManufacturer         - getting the manufacturer of the UPS
#   getModel                - getting the UPS model
#   getVersion              - getting the UPS firmware version
#   printUPSInfo            - printing the informations about the UPS
#   readRatingInfo          - reading the UPS rating info
#   getRatingVoltage        - getting the rating voltage
#   getRatingCurrent        - getting the rating current
#   getRatingBatteryVoltage - getting the rating battery voltage
#   getRatingFrequency      - getting the rating frequency
#   readStatus              - reading the UPS status
#   getInputVoltage         - getting the input voltage
#   getInputFaultVoltage    - getting the input fault voltage
#   getOutputVoltage        - getting the output voltage
#   getUPSLoad              - getting the UPS load
#   getInputFrequency       - getting the input frequency
#   getBatteryVoltage       - getting the battery voltage
#   getUPSTemperature       - getting the UPS temperature
#   getPowerStatus          - getting the power status
#   getBatteryStatus        - getting the battery status
#   getBypassStatus         - getting the bypass status
#   getFailedStatus         - getting the failed status
#   getStandbyStatus        - getting the standby status
#   getTestStatus           - getting the test status
#   getShutdownStatus       - getting the shutdown status
#   getBeeperStatus         - getting the beeper status
#   resetMinMax             - resetting minima and maxima
#   printMinMax             - getting minima and maxima
#   printData               - printing comparison between firmware and status
#   printStatus             - printing status flags
#   toggleBeeper            - toggles the beeper state
#   testUPS                 - testing the UPS
#   testUPSBatteryLow       - testing the UPS until battery low occurs
#   testUPSPeriod           - testing the UPS for a period of time in minutes
#   cancelTest              - cancel testing of the UPS
#   shutdownUPS             - shutdown of the UPS
#   shutdownRestore         - shutdown and restore of the UPS
#   cancelShutdown          - cancel shutdown of the UPS
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
# Revision        : $Revision: 1.13 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/17 19:43:42 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
#   $Log: Megatec.pm,v $
#   Revision 1.13  2007/04/17 19:43:42  creile
#   documentation bugfixes.
#
#   Revision 1.12  2007/04/14 09:38:14  creile
#   documentation update.
#
#   Revision 1.11  2007/04/07 15:21:40  creile
#   Megatec protocol completed (test, shutdown and
#   shutdown/restore of UPS);
#   adaptations to "best practices" style;
#   update of documentation.
#
#   Revision 1.10  2007/03/13 17:15:14  creile
#   usage of Perl pragma constant for most of the package
#   variables;
#   options as anonymous hashes;
#   format directives revised;
#   reconnect fixed.
#
#   Revision 1.9  2007/03/03 21:26:10  creile
#   "return undef" replaced by "return";
#   adaptations to new Constants.pm;
#   formatted output of UPS information, status and data revised
#   using new logging method write();
#   method getMinMax() replaced by printMinMax().
#
#   Revision 1.8  2007/02/25 17:06:26  creile
#   connection as option now;
#   option handling redesigned.
#
#   Revision 1.7  2007/02/05 20:58:43  creile
#   initialization of logger in method() added;
#   pod documentation revised.
#
#   Revision 1.6  2007/02/04 18:57:51  creile
#   bug fix of pod documentation.
#
#   Revision 1.5  2007/02/04 14:11:03  creile
#   package renamed to Hardware::UPS::Perl::Driver::Megatec;
#   output of methods printData(), printStatus() and printUPSInfo()
#   revised;
#   logging support added;
#   update of documentation.
#
#   Revision 1.4  2007/01/28 21:08:24  creile
#   call of method flush() removed from method sendCommand() to avoid deep recursion error;
#   flush() is called now, if sendCommand() was unsuccessful.
#
#   Revision 1.3  2007/01/28 05:32:12  creile
#   renamed to Hardware::UPS::Perl::Megatec;
#   Exporter package removed;
#   network support added;
#   new methods setHost(), getHost(), setTCPPort(), getTCPPort()
#   added;
#   unnecessary comments removed;
#   update of pod documentation.
#
#   Revision 1.2  2007/01/21 15:04:06  creile
#   some beautifications.
#
#   Revision 1.1  2007/01/20 08:11:12  creile
#   initial revision
#
#
#==============================================================================

#==============================================================================
# module preamble:
#==============================================================================

use strict;

BEGIN {

    use vars qw($VERSION @ISA);

    $VERSION = sprintf( "%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/ );

    @ISA     = qw();

}

#==============================================================================
# end of module preamble
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   Hardware::UPS::Perl::Connection - importing Hardware::UPS::Perl connection
#   Hardware::UPS::Perl::Constants  - importing Hardware::UPS::Perl constants
#   Hardware::UPS::Perl::Logging    - importing Hardware::UPS::Perl methods
#                                     dealing with logfiles
#   Hardware::UPS::Perl::Utils      - importing Hardware::UPS::Perl utility
#                                     functions for packages
#
#==============================================================================

use Hardware::UPS::Perl::Connection;
use Hardware::UPS::Perl::Constants qw(
    UPSSCRIPT
);
use Hardware::UPS::Perl::Logging;
use Hardware::UPS::Perl::Utils qw(
    error
);

#==============================================================================
# defining user invisible package constants and variables:
#------------------------------------------------------------------------------
# 
#   F_CMD_REPLY_SIZE                - the reply length for the F command
#   I_CMD_REPLY_SIZE                - the reply length for the I command
#   M_CMD_REPLY_SIZE                - the reply length for the M command
#   Q1_CMD_REPLY_SIZE               - the reply length for the Q1 command
#
#   INPUT_VOLTAGE_MINIMUM_INIT      - the initial minimum input voltage
#   INPUT_VOLTAGE_MAXIMUM_INIT      - the initial maximum input voltage 
#   INPUT_FREQUENCY_MINIMUM_INIT    - the initial minimum input frequency 
#   INPUT_FREQUENCY_MAXIMUM_INIT    - the initial maximum input frequency 
#
#   $PRINT_UPS_INFO                 - the string declaring the format of
#                                     writing the UPS info to the log file
#   $PRINT_DATA                     - the string declaring the format of
#                                     writing the UPS data to the log file
#   $PRINT_STATUS                   - the string declaring the format of
#                                     writing the UPS status to the log file
# 
#==============================================================================

use constant F_CMD_REPLY_SIZE               =>   21;
use constant I_CMD_REPLY_SIZE               =>   38;
use constant M_CMD_REPLY_SIZE               =>    1;
use constant Q1_CMD_REPLY_SIZE              =>   46;

use constant INPUT_VOLTAGE_MINIMUM_INIT     =>  240; 
use constant INPUT_VOLTAGE_MAXIMUM_INIT     =>  210; 
use constant INPUT_FREQUENCY_MINIMUM_INIT   =>   55; 
use constant INPUT_FREQUENCY_MAXIMUM_INIT   =>   45; 

my $PRINT_UPS_INFO               = <<EOF;
format PRINT_UPS_INFO =
=============================================
 UPS Information:
---------------------------------------------
    - UPS Manufacturer: @<<<<<<<<<<<<<<<<
\$manufacturer
    - UPS Model       : @<<<<<<<<<<<
\$model
    - UPS Version     : @<<<<<<<<<<<
\$version
=============================================
.
EOF

my $PRINT_DATA                   = <<EOF;
format PRINT_DATA =
=============================================
 UPS Data at date @<<<<<<<<<<<<<<<<<<<<<<<<
\$date
=============================================
+---------------------+---------------------+
| Nominal:            | Current:            |
+---------------------+---------------------+
|                     | Vin  =@###.# V      |
\$inputVoltage
+---------------------+---------------------+
| Vref =@###.# V      | Vout =@###.# V      |
\$ratingVoltage, \$outputVoltage
+---------------------+---------------------+
| IMax =@###.# A      | Load =@##### %      |
\$ratingCurrent, \$upsLoad
+---------------------+---------------------+
| Batt =@###.# V      | Batt =@###.# V      |
\$ratingBatteryVoltage, \$batteryVoltage
+---------------------+---------------------+
| Freq =@###.# Hz     | Freq =@###.# Hz     |
\$ratingFrequency, \$inputFrequency
+---------------------+---------------------+
|                     | Temp =@###.# °C     |
\$upsTemperature
+---------------------+---------------------+
=============================================
.
EOF

my $PRINT_STATUS                 = <<EOF;
format PRINT_STATUS =
=============================================
 UPS Status at date @<<<<<<<<<<<<<<<<<<<<<<<<
\$date
---------------------------------------------
    - Net:@<<<<V/@<<<Hz=@<<<<<<
\$inputVoltage, \$inputFrequency, \$powerStatus
    - Battery:@<<<V=@<<<
\$batteryVoltage, \$batteryStatus
    - Bypass=@<<<<<<
\$bypassStatus
    - UPS=@*, @*
\$failedStatus, \$standbyStatus
    - Test=@<<<<<<
\$testStatus
    - Shutdown=@<<<<<<
\$shutdownStatus
    - Beeper=@<<<
\$beeperStatus
=============================================
.
EOF

#==============================================================================
# public methods:
#==============================================================================

sub new {

    # public method to construct an UPS object
    #
    # parameters: $class   (input) - class
    #             $options (input) - anonymous hash; options
    #
    # The following option keys are recognized:
    #
    #   Connection  ($) - the connection; a Hardware::UPS::Perl::Conection
    #                     object;
    #   Logger      ($) - Hardware::UPS::Perl::Logging object; the logger to
    #                     use; optional

    # input as hidden local variables
    my $class   = shift;
    my $options = @_ ? shift : {};

    # hidden local variables
    my $self    = {};       # referent to be blessed
    my $option;             # an option
    my $optionRefType;      # the reference type of the option input
    my $logger;             # the logger object
    my $connection;         # the connection object

    # blessing UPS object
    bless $self, $class;

    # checking options
    $optionRefType = ref($options);
    if ($optionRefType ne 'HASH') {
        error("not a hash reference -- <$optionRefType>");
    }

    # the logger; if we don't have one, we have to create our own with output
    # on STDERR
    $logger = delete $options->{Logger};

    if (!defined $logger) {
        $logger = Hardware::UPS::Perl::Logging->new()
            or return;
    }

    # the connection
    $connection = delete $options->{Connection};

    # checking for misspelled options
    foreach $option (keys %{$options}) {
        error("option unknown -- $option");
    }

    # initializing
    $self->{ ups    }->{ manufacturer        } = q{};
    $self->{ ups    }->{ model               } = q{};
    $self->{ ups    }->{ version             } = q{};

    $self->{ rating }->{ voltage             } = 0;
    $self->{ rating }->{ current             } = 0;
    $self->{ rating }->{ battery_voltage     } = 0;
    $self->{ rating }->{ frequency           } = 0;

    $self->{ status }->{ input_voltage       } = 0;
    $self->{ status }->{ input_voltage_fault } = 0;
    $self->{ status }->{ output_voltage      } = 0;
    $self->{ status }->{ ups_load            } = 0;
    $self->{ status }->{ input_frequency     } = 0;
    $self->{ status }->{ battery_voltage     } = 0;
    $self->{ status }->{ ups_temperature     } = 0;
    $self->{ status }->{ power               } = 0;    # Bit7: Utility Fail (Immediate)
    $self->{ status }->{ battery_low         } = 0;    # Bit6: Battery Low
    $self->{ status }->{ bypass              } = 0;    # Bit5: Bypass/Boost or Buck Active
    $self->{ status }->{ failed              } = 0;    # Bit4: UPS Failed
    $self->{ status }->{ standby             } = 0;    # Bit3: UPS Type is Standby (0 is On_line)
    $self->{ status }->{ test                } = 0;    # Bit2: Test in progress
    $self->{ status }->{ shutdown            } = 0;    # Bit1: Shutdown active
    $self->{ status }->{ beeper              } = 0;    # Bit0: Beeper on

    $self->{ errorMessage                    } = q{};

    # the logger
    $self->setLogger($logger);

    # the connection
    $self->setConnection($connection);

    # initializing minima and maxima
    $self->resetMinMax();

    # initializing debug level 
    $self->setDebugLevel(0);

    # returning blessed UPS object
    return $self;

} # end of public method "new"

sub setDebugLevel {

    # public method to set the debug level, the higher, the better
    #
    # parameters: $self       (input) - referent to an UPS object
    #             $debugLevel (input) - the debug level

    # input as hidden local variables
    my $self       = shift;

    @_ == 1 or error("usage: setDebugLevel(debugLevel)");
    my $debugLevel = shift;

    # getting old debug level
    my $oldDebugLevel = $self->getDebugLevel();

    # setting debug level
    $self->{debugLevel} = $debugLevel;

    # promoting it to connection
    my $connection = $self->getConnection();
    if (defined $connection) {
        $connection->getConnectionHandle()->setDebugLevel($debugLevel);
        $self->{connection} = $connection;
    }

    # returning old debug level
    return $oldDebugLevel;

} # end of public method "setDebugLevel"

sub getDebugLevel {

    # public method to get the current debug level
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting debug level
    if (exists $self->{debugLevel}) {
        return $self->{debugLevel};
    }
    else {
        return;
    }

} # end of public method "getDebugLevel"

sub setConnection {

    # public method to set the connection
    #
    # parameters: $self       (input) - referent to an UPS object
    #             $connection (input) - the connection object

    # input as hidden local variables
    my $self       = shift;

    1 == @_ or error("usage: setConnection(CONNECTION)");
    my $connection = shift;

    if (defined $connection) {
        my $connectionRefType = ref($connection);
        if ($connectionRefType ne 'Hardware::UPS::Perl::Connection') {
            error("no connection -- <$connectionRefType>");
        }
    }

    # getting old connection
    my $oldConnection = $self->getConnection();

    # setting connection
    $self->{connection} = $connection;

    # returning old connection
    return $oldConnection;

} # end of public method "setConnection"

sub getConnection {

    # public method to get the current connection
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting connection
    if (exists $self->{connection}) {
        return $self->{connection};
    }
    else {
        return;
    }

} # end of public method "getConnection"

sub setLogger {

    # public method to set the logger
    #
    # parameters: $self   (input) - referent to an UPS object
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

    # setting logger
    $self->{logger} = $logger;

    # returning old logger
    return $oldLogger;

} # end of public method "setLogger"

sub getLogger {

    # public method to get the current logger
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting debug level
    if (exists $self->{logger} ) {
        return $self->{logger};
    }
    else {
        return;
    }

} # end of public method "getLogger"

sub getErrorMessage {

    # public method to get the current error message
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting debug level
    if (exists $self->{errorMessage}) {
        return $self->{errorMessage};
    }
    else {
        return;
    }

} # end of public method "getErrorMessage"

sub connect {

    # public method to connect to an UPS agent or the serial port an UPS
    # resides
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # checking connection type
    my $connection = $self->getConnection();
    if (defined $connection and !$connection->connect(@_)) {
        $self->{errorMessage}
            = "connection failed -- ".$connection->getErrorMessage();
        return 0;
    }
    else {
        $self->{errorMessage} = "connection unavailable";
        return 0;
    }

    # flushing any buffered input
    $self->flush();

    return 1;

} # end of public method "connect"

sub connected {

    # public method to test the connection status
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # checking for connection
    my $connection = $self->getConnection();
    if (defined $connection) {
        return $connection->connected();
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
        $self->{connection}->disconnect();

        return 1;

    } else {

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
    my $connection;         # the connection

    # getting connection
    $connection = $self->getConnection();
    if (! defined $connection) {
        $self->{errorMessage} = "no connection available";
        return 0;
    }

    # send message to UPS
    if (!$connection->sendCommand($command, $response, $responseSize)) {
        $self->{errorMessage} = $connection->getErrorMessage();
        return 0
    }

    # checking for command being successfull
    # If the UPS receives any command that it could not handle, the UPS should
    # echo the received command back to the computer. The host should check if
    # the command sent to UPS been echo or not.
    if ($command eq $$response) {
        $self->{errorMessage} = "command $command unknown to UPS";
        return 0;
    }
    else {
        if ($$response or ($responseSize == 0)) {
            return 1;
        }
        else {
            $self->{errorMessage} = "no response to command $command";
            return 0;
        }
    }

} # end of public method "sendCommand"

sub flush {

    # public method to flush any buffered input at the UPS
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $response = q{};     # response from the UPS

    # flushing UPS communication
    return $self->sendCommand(q{M}, \$response, M_CMD_REPLY_SIZE);

} # end of public method "flush"

sub readUPSInfo {

    # public method to read the UPS info about the manufacturer, model and
    # firmware version
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $response = q{};     # response from the UPS

    # getting UPS rating info
    if ($self->sendCommand(q{I}, \$response, I_CMD_REPLY_SIZE)) {

        $response =~ /\#(...............) (..........) (..........)/;

        $self->{ ups }->{ manufacturer } = $1;
        $self->{ ups }->{ model        } = $2;
        $self->{ ups }->{ version      } = $3;

        return 1;

    }
    else {

        $self->flush();

        if (2 < $self->getDebugLevel()) {
            my $logger = $self->getLogger();
            if (defined $logger) {
                $logger->debug($self->getErrorMessage())
            }
        }

        return 0;

    }

} # end of public method "readUPSInfo"

sub getManufacturer {

    # public method to get the UPS manufacturer
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting the UPS manufacturer
    if (exists $self->{ ups }->{ manufacturer }) {
        return $self->{ ups }->{ manufacturer };
    }
    else {
        return;
    }

} # end of public method "getManufacturer"

sub getModel {

    # public method to get the UPS model
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting UPS model
    if (exists $self->{ ups }->{ model }) {
        return $self->{ ups }->{ model };
    }
    else {
        return;
    }

} # end of public method "getModel"

sub getVersion {

    # public method to get the UPS firmware version
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting UPS firmware version
    if (exists $self->{ ups }->{ version }) {
        return $self->{ ups }->{ version };
    }
    else {
        return;
    }

} # end of public method "getVersion"

sub printUPSInfo {

    # public method to print the UPS informations (manufacturer, model and
    # firmware version) to logger
    #
    # parameters: $self (input) - referent to an UPS object
    #             $type (input) - output type

    # input as hidden local variables
    my $self = shift;
    my $type = @_ ? shift : "none";

    # hidden local variables
    my $manufacturer;       # the manufacturer
    my $model;              # the model
    my $version;            # the firmware version

    my $logger;             # the logger
    my $return;             # the logger's return value

    # getting status flags
    $manufacturer
        = $self->{ ups }->{ manufacturer } ? $self->{ ups }->{ manufacturer }
        :                                    "unknown"
        ;
    $model
        = $self->{ ups }->{ model        } ? $self->{ ups }->{ model        }
        :                                    "unknown"
        ;
    $version
        = $self->{ ups }->{ version      } ? $self->{ ups }->{ version      }
        :                                    "unknown"
        ;

    # printing UPS information
    $logger = $self->getLogger();
    $return = $logger->write({
        Format      =>  $PRINT_UPS_INFO,
        Type        =>  $type,
        Arguments   =>  {
                            manufacturer    => $manufacturer,
                            model           => $model,
                            version         => $version,
                        },
    });

    if (!$return) {
        $self->{errorMessage} = $logger->getErrorMessage();
    }

    return $return

} # end of public method "printUPSInfo"

sub readRatingInfo {

    # public method to read the UPS rating info (firmware data)
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $response = q{};     # response from the UPS

    # getting UPS rating info
    if ($self->sendCommand(q{F}, \$response, F_CMD_REPLY_SIZE)) {

        $response =~ /\#(.....) ..(.) (.....) (....)/;

        $self->{ rating }->{ voltage         } = $1;
        $self->{ rating }->{ current         } = $2;
        $self->{ rating }->{ battery_voltage } = $3;
        $self->{ rating }->{ frequency       } = $4;

        return 1;

    } else {

        $self->flush();

        if (2 < $self->getDebugLevel()) {
            my $logger = $self->getLogger();
            if (defined $logger) {
                $logger->debug($self->getErrorMessage())
            }
        }

        return 0;

    }

} # end of public method "readRatingInfo"

sub getRatingVoltage {

    # public method to get the rating voltage of the UPS (firmware)
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting rating voltage
    if (exists $self->{ rating }->{ voltage }) {
        return $self->{ rating }->{ voltage };
    }
    else {
        return;
    }

} # end of public method "getRatingVoltage"

sub getRatingCurrent {

    # public method to get the rating current of the UPS (firmware)
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting rating voltage
    if (exists $self->{ rating }->{ current }) {
        return $self->{ rating }->{ current };
    }
    else {
        return;
    }

} # end of public method "getRatingCurrent"

sub getRatingBatteryVoltage {

    # public method to get the rating battery voltage of the UPS (firmware)
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting rating battery voltage
    if (exists $self->{ rating }->{ battery_voltage }) {
        return $self->{ rating }->{ battery_voltage };
    }
    else {
        return;
    }

} # end of public method "getRatingBatteryVoltage"

sub getRatingFrequency {

    # public method to get the rating frequency of the UPS (firmware)
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting rating frequency
    if (exists $self->{ rating }->{ frequency }) {
        return $self->{ rating }->{ frequency };
    }
    else {
        return;
    }

} # end of public method "getRatingFrequency"

sub readStatus {

    # public method to read the current UPS status
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $response = q{};     # response from the UPS

    # getting UPS status
    if ($self->sendCommand(q{Q1}, \$response, Q1_CMD_REPLY_SIZE)) {
    
        $response =~ /\((.....) (.....) (.....) (...) (....) (....) (....) (.)(.)(.)(.)(.)(.)(.)(.)/;

        $self->{ status }->{ input_voltage       } = $1;
        $self->{ status }->{ input_voltage_fault } = $2;
        $self->{ status }->{ output_voltage      } = $3;
        $self->{ status }->{ ups_load            } = $4;
        $self->{ status }->{ input_frequency     } = $5;
        $self->{ status }->{ battery_voltage     } = $6;
        $self->{ status }->{ ups_temperature     } = $7;
        $self->{ status }->{ power               } = $8;     # Bit7: Utility Fail (Immediate)
        $self->{ status }->{ battery_low         } = $9;     # Bit6: Battery Low
        $self->{ status }->{ bypass              } = $10;    # Bit5: Bypass/Boost or Buck Active
        $self->{ status }->{ failed              } = $11;    # Bit4: UPS Failed
        $self->{ status }->{ standby             } = $12;    # Bit3: UPS Type is Standby (0 is On_line)
        $self->{ status }->{ test                } = $13;    # Bit2: Test in progress
        $self->{ status }->{ shutdown            } = $14;    # Bit1: Shutdown active
        $self->{ status }->{ beeper              } = $15;    # Bit0: Beeper on

        # setting minima and maxima
        if ($self->{ status }->{ input_voltage_maximum } < $1) {
            $self->{ status }->{ input_voltage_maximum } = $1;
        }
        if ($self->{ status }->{ input_voltage_minimum } > $1) {
            $self->{ status }->{ input_voltage_minimum } = $1;
        }

        if ($self->{ status }->{ frequency_maximum     } < $5) {
            $self->{ status }->{ frequency_maximum     } = $5;
        }
        if ($self->{ status }->{ frequency_minimum     } > $5) {
            $self->{ status }->{ frequency_minimum     } = $5;
        }

        return 1;

    }
    else {

        $self->flush();

        if (2 < $self->getDebugLevel()) {
            my $logger = $self->getLogger();
            if (defined $logger) {
                $logger->debug($self->getErrorMessage())
            }
        }

        return 0;

    }

} # end of public method "readStatus"

sub getInputVoltage {

    # public method to get the current input voltage of the UPS
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting the input voltage
    if (exists $self->{ status }->{ input_voltage }) {
        return $self->{ status }->{ input_voltage };
    }
    else {
        return;
    }

} # end of public method "getInputVoltage"

sub getInputFaultVoltage {

    # public method to get the current input fault voltage of the UPS
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting the input fault voltage
    if (exists $self->{ status }->{ input_voltage_fault }) {
        return $self->{ status }->{ input_voltage_fault };
    }
    else {
        return;
    }

} # end of public method "getInputFaultVoltage"

sub getOutputVoltage {

    # public method to get the current power status of the UPS
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting output voltage
    if (exists $self->{ status }->{ output_voltage }) {
        return $self->{ status }->{ output_voltage };
    }
    else {
        return;
    }

} # end of public method "getOutputVoltage"

sub getUPSLoad {

    # public method to get the current UPS load
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting UPS load
    if (exists $self->{ status }->{ ups_load }) {
        return $self->{ status }->{ ups_load };
    }
    else {
        return;
    }

} # end of public method "getUPSLoad"

sub getInputFrequency {

    # public method to get the current input frequency of the UPS
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting the input frequency
    if (exists $self->{ status }->{ input_frequency }) {
        return $self->{ status }->{ input_frequency };
    }
    else {
        return;
    }

} # end of public method "getInputFrequency"

sub getBatteryVoltage {

    # public method to get the current battery voltage
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting the current battery voltage
    if (exists $self->{ status }->{ battery_voltage } ) {
        return $self->{ status }->{ battery_voltage };
    }
    else {
        return;
    }

} # end of public method "getBatteryVoltage"

sub getUPSTemperature {

    # public method to get the current UPS temperature
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting the UPS temperature
    if (exists $self->{ status }->{ ups_temperature } ) {
        return $self->{ status }->{ ups_temperature };
    }
    else {
        return;
    }

} # end of public method "getUPSTemperature"

sub getPowerStatus {

    # public method to get the current power status of the UPS
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting power status
    if (exists $self->{ status }->{ power }) {
        return $self->{ status }->{ power };
    }
    else {
        return;
    }

} # end of public method "getPowerStatus"

sub getBatteryStatus {

    # public method to get the current battery status of the UPS
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting battery status
    if (exists $self->{ status }->{ battery_low } ) {
        return $self->{ status }->{ battery_low };
    }
    else {
        return;
    }

} # end of public method "getBatteryStatus"

sub getBypassStatus {

    # public method to get the current bypass status of the UPS, i.e. whether
    # bypass/boost or buck is active
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting bypass status
    if (exists $self->{ status }->{ bypass } ) {
        return $self->{ status }->{ bypass };
    }
    else {
        return;
    }

} # end of public method "getBypassStatus"

sub getFailedStatus {

    # public method to get the current failed status of the UPS, i.e. UPS
    # failed
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting failed status
    if (exists $self->{ status }->{ failed } ) {
        return $self->{ status }->{ failed };
    }
    else {
        return;
    }

} # end of public method "getFailedStatus"

sub getStandbyStatus {

    # public method to get the current standby status of the UPS, i.e. whether
    # the UPS is standby (1) or online (0)
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting standby status
    if (exists $self->{ status }->{ standby }) {
        return $self->{ status }->{ standby };
    }
    else {
        return;
    }

} # end of public method "getStandbyStatus"

sub getTestStatus {

    # public method to get the current test status of the UPS, i.e. whether
    # a test of the UPS is in progress
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting test status
    if (exists $self->{ status }->{ test }) {
        return $self->{ status }->{ test };
    }
    else {
        return;
    }

} # end of public method "getTestStatus"

sub getShutdownStatus {

    # public method to get the current shutdown status of the UPS, i.e.
    # whether a shutdown is active or not
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting shutdown status
    if (exists $self->{ status }->{ shutdown }) {
        return $self->{ status }->{ shutdown };
    }
    else {
        return;
    }

} # end of public method "getShutdownStatus"

sub getBeeperStatus {

    # public method to get the current beeper status of the UPS, i.e. whether
    # the beeper is on or not
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # getting beeper status
    if (exists $self->{ status }->{ beeper }) {
        return $self->{ status }->{ beeper };
    }
    else {
        return;
    }

} # end of public method "getBeeperStatus"

sub resetMinMax {

    # public method to reset the minima and maxima of the input voltage
    # and frequency
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # resetting minima and maxima
    $self->{ status }->{ input_voltage_minimum } = INPUT_VOLTAGE_MINIMUM_INIT;
    $self->{ status }->{ input_voltage_maximum } = INPUT_VOLTAGE_MAXIMUM_INIT;

    $self->{ status }->{ frequency_minimum     } = INPUT_FREQUENCY_MINIMUM_INIT;
    $self->{ status }->{ frequency_maximum     } = INPUT_FREQUENCY_MAXIMUM_INIT;

    return;

} # end of public method "resetMinMax"

sub printMinMax {

    # public method to print the minima and maxima of the input voltage
    # and frequency
    #
    # parameters: $self  (input) - referent to an UPS object
    #             $level (input) - the logging level

    # input as hidden local variable
    my $self  = shift;
    my $level = @_ ? shift : "syslog";

    # hidden local variables
    my $message;            # message
    my %levelTable;         # the level table
    my $logger;             # the logger
    my $return;             # the logger's return value

    # getting the logger
    $logger = $self->getLogger();

    # printing minima and maxima
    $message  = "Line max=".$self->{ status }->{ input_voltage_maximum };
    $message .= "V/"       .$self->{ status }->{ frequency_maximum     };
    $message .= "Hz - min=".$self->{ status }->{ input_voltage_minimum };
    $message .= "V/"       .$self->{ status }->{ frequency_minimum     };
    $message .= "Hz"; 

    %levelTable = (
        debug   =>  sub { return $logger->debug ($message); },
        info    =>  sub { return $logger->info  ($message); },
        error   =>  sub { return $logger->error ($message); },
        fatal   =>  sub { return $logger->fatal ($message); },
        syslog  =>  sub { return $logger->syslog($message); },
    );

    if (exists $levelTable{$level}) {
            $return = $levelTable{$level}->();
    }
    else {
        error("unknown printing level -- $level");
    }

    if (!$return) {
        $self->{errorMessage} = $logger->getErrorMessage();
    }
                            
    return $return;

} # end of public method "printMinMax"

sub printData {

    # public method to print the comparison between the rating info (firmware
    # data) and the current data of the UPS to a logger
    #
    # parameters: $self (input) - referent to an UPS object
    #             $type (input) - output type

    # input as hidden local variables
    my $self = shift;
    my $type = @_ ? shift : "none";

    # hidden local variables
    my $logger;             # the logger
    my $return;             # the logger's return value

    # printing UPS data
    $logger = $self->getLogger();
    $return = $logger->write({
        Format      =>  $PRINT_DATA,
        Type        =>  $type,
        Arguments   =>
            {
                date                    => scalar localtime,
                inputVoltage            => $self->{ status }->{ input_voltage   },
                ratingVoltage           => $self->{ rating }->{ voltage         },
                outputVoltage           => $self->{ status }->{ output_voltage  },
                ratingCurrent           => $self->{ rating }->{ current         },
                upsLoad                 => $self->{ status }->{ ups_load        },
                ratingBatteryVoltage    => $self->{ rating }->{ battery_voltage },
                batteryVoltage          => $self->{ status }->{ battery_voltage },
                ratingFrequency         => $self->{ rating }->{ frequency       },
                inputFrequency          => $self->{ status }->{ input_frequency },
                upsTemperature          => $self->{ status }->{ ups_temperature },
            },
    });

    if (!$return) {
        $self->{errorMessage} = $logger->getErrorMessage();
    }

    return $return

} # end of public method "printData"

sub printStatus {

    # public method to print the status flags in a human readable format to
    # a logger
    #
    # parameters: $self (input) - referent to an UPS object
    #             $type (input) - output type

    # input as hidden local variables
    my $self = shift;
    my $type = @_ ? shift : "none";

    # hidden local variables
    my $powerStatus;                # the power status (FAILED/OK)
    my $batteryStatus;              # the battery status (LOW/OK)
    my $bypassStatus;               # the bypass status (ON/OFF)
    my $failedStatus;               # the failed status (FAILED/OK)
    my $standbyStatus;              # the standby status (Online/OFF)
    my $testStatus;                 # the test status (ON/OFF)
    my $shutdownStatus;             # the shutdown status (ON/OFF)
    my $beeperStatus;               # the beeper status (ON/OFF)

    my $logger;                     # the logger
    my $return;                     # the logger's return value

    # getting status flags
    $powerStatus    = $self->{ status }->{ power       } ? "FAILED" : "OK";
    $batteryStatus  = $self->{ status }->{ battery_low } ? "LOW"    : "OK";
    $bypassStatus   = $self->{ status }->{ bypass      } ? "ON"     : "OFF";
    $failedStatus   = $self->{ status }->{ failed      } ? "FAILED" : "OK";
    $standbyStatus  = $self->{ status }->{ standby     } ? "ONLINE" : "OFF";
    $testStatus     = $self->{ status }->{ test        } ? "ON"     : "OFF";
    $shutdownStatus = $self->{ status }->{ shutdown    } ? "ON"     : "OFF";
    $beeperStatus   = $self->{ status }->{ beeper      } ? "ON"     : "OFF";

    # printing UPS status
    $logger = $self->getLogger();

    $return = $logger->write({
        Format      =>  $PRINT_STATUS,
        Type        =>  $type,
        Arguments   =>  {
                            date            => scalar localtime,
                            inputVoltage    => $self->{ status }->{ input_voltage   },
                            inputFrequency  => $self->{ status }->{ input_frequency },
                            powerStatus     => $powerStatus,
                            batteryVoltage  => $self->{ status }->{ battery_voltage },
                            batteryStatus   => $batteryStatus,
                            bypassStatus    => $bypassStatus,
                            failedStatus    => $failedStatus,
                            standbyStatus   => $standbyStatus,
                            testStatus      => $testStatus,
                            shutdownStatus  => $shutdownStatus,
                            beeperStatus    => $beeperStatus,
                        },
    });

    if (!$return) {
        $self->{errorMessage} = $logger->getErrorMessage();
    }

    return $return

} # end of public method "printStatus"

sub toggleBeeper {

    # public method to toggle the beeper state from ON to OFF and vice versa
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $response = q{};     # response from the UPS

    # toggle beeper
    if ($self->sendCommand(q{Q}, \$response, 0)) {

        # success
        $self->flush();
        return 1;

    }
    else {

        # error, so clearing UPS buffer
        $self->flush();

        if (2 < $self->getDebugLevel()) {
            my $logger = $self->getLogger();
            if (defined $logger) {
                $logger->debug($self->getErrorMessage())
            }
        }

        return 0;

    }

} # end of public method "toggleBeeper"

sub testUPS {

    # public method to test the UPS for 10 seconds
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $response = q{};     # response from the UPS

    # test UPS
    if ($self->sendCommand(q{T}, \$response, 0)) {

        # success
        $self->flush();
        return 1;

    }
    else {

        # error, so clearing UPS buffer
        $self->flush();

        if (2 < $self->getDebugLevel()) {
            my $logger = $self->getLogger();
            if (defined $logger) {
                $logger->debug($self->getErrorMessage())
            }
        }

        return 0;

    }

} # end of public method "testUPS"

sub testUPSBatteryLow {

    # public method to test the UPS until the battery low occurs
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $response = q{};     # response from the UPS

    # test UPS
    if ($self->sendCommand(q{TL}, \$response, 0)) {

        # success
        $self->flush();
        return 1;

    }
    else {

        # error, so clearing UPS buffer
        $self->flush();
        
        if (2 < $self->getDebugLevel()) {
            my $logger = $self->getLogger();
            if (defined $logger) {
                $logger->debug($self->getErrorMessage())
            }
        }

        return 0;

    }

} # end of public method "testUPSBatteryLow"

sub testUPSPeriod {

    # public method to test the UPS for a certain period of time in minutes
    #
    # parameters: $self   (input) - referent to an UPS object
    #             $period (input) - the period of time to test the UPS in
    #                               minutes

    # input as hidden local variables
    my $self   = shift;
    my $period = @_ ? shift : undef;

    # hidden local variables
    my $response = q{};     # response from the UPS
    my $command;            # command to the UPS

    # checking period
    if (defined $period) {

        # period is not a number
        if ($period !~ m{\A \d+ \z}xms) {
            $self->{errorMessage}
                = "invalid period to test the UPS -- $period";
            return 0;
        }

        # period is out of range
        if (0 >= $period or $period > 99) {
            $self->{errorMessage}
                = "period to test the UPS out of range -- $period";
            return 0;
        }

        # the command
        $command = q{T} . sprintf( "%02d" , $period );

    }
    else {

        # period is undefined
        $self->{errorMessage} = "period to test the UPS undefined";
        return 0;

    }

    # testing UPS
    if ($self->sendCommand($command, \$response, 0)) {

        # success
        $self->flush();
        return 1;

    }
    else {

        # error, so clearing UPS buffer
        $self->flush();

        if (2 < $self->getDebugLevel()) {
            my $logger = $self->getLogger();
            if (defined $logger) {
                $logger->debug($self->getErrorMessage())
            }
        }

        return 0;

    }

} # end of public method "testUPSPeriod"

sub cancelTest {

    # public method to cancel a running test of the UPS
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $response = q{};     # response from the UPS

    # test UPS
    if ($self->sendCommand(q{CT}, \$response, 0)) {

        # success
        $self->flush();
        return 1;

    } else {

        # error, so clearing UPS buffer
        $self->flush();

        if (2 < $self->getDebugLevel()) {
            my $logger = $self->getLogger();
            if (defined $logger) {
                $logger->debug($self->getErrorMessage())
            }
        }

        return 0;

    }

} # end of public method "cancelTest"

sub shutdownUPS {

    # public method to shutdown the UPS in a certain period of time in minutes
    #
    # parameters: $self (input) - referent to an UPS object
    #             $time (input) - the time left in minutes, until the UPS will
    #                             be shutdown

    # input as hidden local variables
    my $self = shift;
    my $time = @_ ? shift : undef;

    # hidden local variables
    my $response = q{};     # response from the UPS
    my $command;            # command to the UPS

    # checking time
    if (defined $time) {

        # time is not a number
        if ($time !~ m{\A \d?\.?\d+ \z}xms ) {
            $self->{errorMessage}
                = "invalid time left to shutdown the UPS -- $time";
            return 0;
        }

        # time is out of range
        if (0 >= $time or $time > 10) {
            $self->{errorMessage}
                = "time left to shutdown the UPS out of range -- $time";
            return 0;
        }

        # the command
        if ($time < 1) {
            $command = q{S} . sprintf( "%.2f" , $time );
        }
        else {
            $command = q{S} . sprintf( "%02d" , $time );
        }

    } else {

        $self->{errorMessage} = "time left to shutdown the UPS undefined";
        return 0;

    }

    # shutdown of UPS
    if ($self->sendCommand($command, \$response, 0)) {

        # success
        $self->flush();
        return 1;

    }
    else {

        # error, so clearing UPS buffer
        $self->flush();

        if (2 < $self->getDebugLevel()) {
            my $logger = $self->getLogger();
            if (defined $logger) {
                $logger->debug($self->getErrorMessage())
            }
        }

        return 0;

    }

} # end of public method "shutdownUPS"

sub shutdownRestore {

    # public method to shutdown the UPS after a certain period of time in
    # minutes and turn it on again after another period of time in minutes
    #
    # parameters: $self           (input) - referent to an UPS object
    #             $shutdownPeriod (input) - the period of time in minutes,
    #                                       until the UPS will be shutdown
    #             $restorePeriod  (input) - the period of time in minutes,
    #                                       until the UPS will be restored
    #                                       again

    # input as hidden local variables
    my $self           = shift;
    my $shutdownPeriod = @_ ? shift : undef;
    my $restorePeriod  = @_ ? shift : undef;

    # hidden local variables
    my $response = q{};     # response from the UPS
    my $command;            # command to the UPS

    # checking shutdown period
    if (defined $shutdownPeriod) {

        # shutdown period is not a decimal number
        if ($shutdownPeriod !~ m{\A \d?\.?\d+ \z}xms ) {
            $self->{errorMessage}
                = "invalid time left to shutdown the UPS -- $shutdownPeriod";
            return 0;
        }

        # shutdown period is out of range
        if (0 >= $shutdownPeriod or $shutdownPeriod > 10) {
            $self->{errorMessage}
                = "time left to shutdown the UPS out of range -- $shutdownPeriod";
            return 0;
        }

        # the command
        if ($shutdownPeriod < 1) {
            $command = q{S} . sprintf( "%.2f" , $shutdownPeriod );
        }
        else {
            $command = q{S} . sprintf( "%02d" , $shutdownPeriod );
        }

    }
    else {

        $self->{errorMessage} = "shutdown period of the UPS undefined";
        return 0;

    }

    # checking restore period
    if (defined $restorePeriod) {

        # restore period is not a decimal number
        if ($restorePeriod !~ m{\A \d?\.?\d+ \z}xms ) {
            $self->{errorMessage}
                = "invalid restore period of the UPS -- $restorePeriod";
            return 0;
        }

        # restore period is out of range
        if (0 >= $restorePeriod or $restorePeriod > 9999) {
            $self->{errorMessage}
                = "restore period of the UPS out of range -- $restorePeriod";
            return 0;
        }

        # the command
        $command .= q{R} . sprintf( "%04d" , $restorePeriod );

    }
    else {

        $self->{errorMessage} = "restore period of the UPS undefined";
        return 0;

    }

    # shutting down UPS and restoring it again
    if ($self->sendCommand($command, \$response, 0)) {

        # success
        $self->flush();
        return 1;

    } else {

        # error, so clearing UPS buffer
        $self->flush();

        if (2 < $self->getDebugLevel()) {
            my $logger = $self->getLogger();
            if (defined $logger) {
                $logger->debug($self->getErrorMessage())
            }
        }

        return 0;

    }

} # end of public method "shutdownRestore"

sub cancelShutdown {

    # public method to cancel a running shutdown of the UPS
    #
    # parameters: $self (input) - referent to an UPS object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $response = q{};     # response from the UPS

    # test UPS
    if ($self->sendCommand(q{C}, \$response, 0)) {

        # success
        $self->flush();
        return 1;

    } else {

        # error, so clearing UPS buffer
        $self->flush();

        if (2 < $self->getDebugLevel()) {
            my $logger = $self->getLogger();
            if (defined $logger) {
                $logger->debug($self->getErrorMessage())
            }
        }

        return 0;

    }

} # end of public method "cancelShutdown"

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

Hardware::UPS::Perl::Driver::Megatec - package of methods for dealing with an
UPS using the Megatec protocol

=head1 SYNOPSIS

    use Hardware::UPS::Perl::Connection;
    use Hardware::UPS::Perl::Driver::Megatec;
    use Hardware::UPS::Perl::Logging;

    $logger     = Hardware::UPS::Perl::Logging->new();

    $connection = Hardware::UPS::Perl::Connection->new({
        Connection  =>  'serial',
        Options     =>  {
                            SerialPort  => '/dev/ttyS0',
                        },
        Logger      =>  $logger,
    });

    $ups  = Hardware::UPS::Perl::Driver::Megatec->new({
        Connection  =>  $connection,
        Logger      =>  $logger,
    });

    $ups->readUPSInfo();
    $ups->printUPSInfo();

    $ups->readStatus();
    $ups->printStatus();

    undef $ups;                        # disconnects

=head1 DESCRIPTION

B<Hardware::UPS::Perl::Driver::Megatec> provides methods dealing with an UPS
using the Megatec protocol. It should be included in your code via the
B<Hardware::UPS::Perl::Driver> module by specifying F<Megatec> as driver name.

=head1 LIST OF METHODS

=head2 new

=over 8

=item B<Name:>

new - creates a new UPS object

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    $ups = Hardware::UPS::Perl::Driver::Megatec->new({
        Connection  => $connection,
    });

=item B<Description:>

B<new> initializes an UPS object $ups using a B<Hardware::UPS::Perl::Conection>
object to connect to an UPS directly or via an UPS agent.

B<new> expects the options as an anonymous hash.

=item B<Arguments:>

=over 8

=item C<< Connection    => $connection >>

optional; a B<Hardware::UPS::Perl::Connection> object; defines the connection
to the UPS.

=item C<< Logger        => $logger >>

optional; a B<Hardware::UPS::Perl::Logging> object; defines a logger; if not
specified, a logger sending its output to STDERR is created.

=back

=item B<See Also:>

L<"connect">,
L<"connected">,
L<"disconnect">,
L<"getLogger">,
L<"setConnection">,
L<"setLogger">

=back

=head2 setDebugLevel

=over 8

=item B<Name:>

setDebugLevel - sets the debug level

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    $ups->setDebugLevel(1);

=item B<Description:>

B<setDebugLevel> sets the debug level, the higher, the better. It returns the
previous one if available, 0 otherwise.

=item B<Arguments:>

=over 8

=item C<< $debugLevel >>

integer number; defines the debug level.

=back

=item B<See Also:>

L<"getDebugLevel">

=back

=head2 getDebugLevel

=over 8

=item B<Name:>

getDebugLevel - gets the current debug level

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    $debugLevel = $ups->getDebugLevel();

=item B<Description:>

B<getDebugLevel> returns the current debug level.

=item B<See Also:>

L<"setDebugLevel">

=back

=head2 setLogger

=over 8

=item B<Name:>

setLogger - sets the logger to use

=item B<Synopsis:>

    $ups    = Hardware::UPS::Perl::Driver::Megatec->new();

    $logger = Hardware::UPS::Perl::Logging->new();

    $ups->setLogger($logger);

=item B<Description:>

B<setLogger> sets the logger object used for logging. B<setLogger> returns the
previous logger used. The logger will be promoted to the current connection.

=item B<Arguments:>

=over 8

=item C<< $logger >>

required; a B<Hardware::UPS::Perl::Logging> object; defines the logger used
for logging.

=back

=item B<See Also:>

L<"new">,
L<"getLogger">

=back

=head2 getLogger

=over 8

=item B<Name:>

getLogger - gets the current logger object

=item B<Synopsis:>

    $ups    = Hardware::UPS::Perl::Driver::Megatec->new();

    $logger = $ups->getLogger();

=item B<Description:>

B<getLogger> returns the current logger object used for logging, if defined,
undef otherwise.

=item B<See Also:>

L<"new">,
L<"setLogger">

=back

=head2 getErrorMessage

=over 8

=item B<Name:>

getErrorMessage - gets the internal error message

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    if (!$ups->connect()) {
        print STDERR $ups->getErrorMessage($errorMessage), "\n";
        exit 0;
    }

=item B<Description:>

B<getErrorMessage> returns the internal error message, if something went
wrong.

=back

=head2 connect

=over 8

=item B<Name:>

connect - connects to an UPS

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();
    $ups->connect($port);   # serial connection

    $ups = Hardware::UPS::Perl::Driver::Megatec->new({
        Connection  => "serial"
    });
    $ups->connect($port);   # serial connection

    $ups = Hardware::UPS::Perl::Driver::Megatec->new({
        Connection  => "tcp"
    });
    $ups->connect();        # TCP connection
    $ups->connect({         # TCP connection
        Host    => $host,
        TCPPort => $tcpport,
    });

=item B<Description:>

B<connect> connects either to an local UPS residing on the port $port using
the method B<connect> of package B<Hardware::UPS::Perl::Connect::Serial> or to
an UPS agent running at a remote host using the method B<connect> of package
B<Hardware::UPS::Perl::Connect::Net>.

=item B<Arguments:>

=over 8

=item C<< $port >>

optional; serial device; defines a valid serial port.

=item C<< SerialPort    => $port >>

optional; serial device; defines a valid serial port.

=item C<< Host          => $host[:$tcpport] >>

optional; host; defines a resolvable host and, optionally, a valid TCP port
separated by ":" to connect to.

=item C<< TCPPort       => $tcpport >>

optional; TCP port; a valid TCP port.

=back

=item B<See Also:>

L<"new">,
L<"connected">,
L<"disconnect">,
L<"getLogger">,
L<"setLogger">

=back

=head2 connected

=over 8

=item B<Name:>

connected - tests the connection status

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    $ups->connect($port);
    if ($ups->connected()) {
        ...
    }

=item B<Description:>

B<connected> tests the connection status, returning 0, when not connected, and
1 when connected.

=item B<See Also:>

L<"new">,
L<"connect">,
L<"disconnect">,
L<"getLogger">,
L<"setLogger">

=back

=head2 disconnect

=over 8

=item B<Name:>

disconnect - disconnects from an UPS

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    $ups->connect($port);
    $ups->disconnect();

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    $ups->connect($port);
    undef $ups;

=item B<Description:>

B<disconnect> disconnects from an UPS or an UPS agent.

=item Notes

C<< undef $ups >> has the same effect as C<< $ups->disconnect() >>.

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"getLogger">,
L<"setLogger">

=back

=head2 sendCommand

=over 8

=item B<Name:>

sendCommand - sending a command to the UPS

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    $ups->connect($port);
    $ups->sendCommand($command, \$response, $responseSize);

=item B<Description:>

B<sendCommand> sends a command to an UPS connected and reads the response from
the UPS using either the package B<Hardware::UPS::Perl::Connect::Net> or
B<Hardware::UPS::Perl::Connect::Serial>. If the command is known by the UPS,
B<sendCommand> returns 1, otherwise 0 setting the internal error message.

=item B<Arguments:>

=over 8

=item C<< $command >>

string; defines a command.

=back

=over 8

=item C<< $response >>

string; the response from the UPS.

=back

=over 8

=item C<< $responseSize >>

integer; the buffer size of the response from the UPS.

=back

=item B<See Also:>

L<"new">,
L<"connect">,
L<"connected">,
L<"readUPSInfo">,
L<"readRatingInfo">,
L<"readStatus">

=back

=head2 flush

=over 8

=item B<Name:>

flush - flushing any buffered input

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    $ups->connect($port);
    $ups->flush();

=item B<Description:>

B<flush> implements the Megatec protocl feature flushing any buffered input on
startup. It sends the F<M> command to an UPS connected.

=item B<See Also:>

L<"connect">,
L<"connected">,
L<"sendCommand">,
L<"readRatingInfo">,
L<"readStatus">,
L<"readUPSInfo">

=back

=head2 readUPSInfo

=over 8

=item B<Name:>

readUPSInfo - reading the UPS information

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    $ups->connect($port);
    $ups->readUPSInfo();

=item B<Description:>

B<readUPSInfo> sends the F<I> command to an UPS connected and processes the
response from the UPS yielding the UPS manufacturer, model, and version.

=item B<See Also:>

L<"sendCommand">,
L<"getManufacturer">,
L<"getModel">,
L<"getVersion">,
L<"printUPSInfo">,
L<"readRatingInfo">,
L<"readStatus">,
L<"readUPSInfo">

=back

=head2 getManufacturer

=over 8

=item B<Name:>

getManufacturer - gets the UPS manufacturer

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

    $ups->readUPSInfo();
    $manufacturer = $ups->getManufacturer();

=item B<Description:>

B<getManufacturer> returns the UPS manufacturer (a string of length 10 at
most), which was determined from the UPS by a previous call of method
L<"readUPSInfo">.

=item B<See Also:>

L<"getModel">,
L<"getVersion">,
L<"printUPSInfo">,
L<"readUPSInfo">

=back

=head2 getModel

=over 8

=item B<Name:>

getModel - gets the UPS model

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

    $ups->readUPSInfo();
    $model = $ups->getModel();

=item B<Description:>

B<getModel> returns the UPS model (a string of length 10 at most), which was
determined from the UPS by a previous call of method L<"readUPSInfo">.

=item B<See Also:>

L<"getManufacturer">,
L<"getVersion">,
L<"printUPSInfo">,
L<"readUPSInfo">

=back

=head2 getVersion

=over 8

=item B<Name:>

B<getVersion> - gets the UPS firmware version

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

    $ups->readUPSInfo();
    $version = $ups->getVersion();

=item B<Description:>

B<getVersion> returns the UPS firmware version (a string of length 10 at
most), which was determined from the UPS by a previous call of method
L<"readUPSInfo">.

=item B<See Also:>

L<"getManufacturer">,
L<"getModel">,
L<"printUPSInfo">,
L<"readUPSInfo">

=back

=head2 printUPSInfo

=over 8

=item B<Name:>

printUPSInfo - printing the UPS information

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

    $ups->readUPSInfo();
    $ups->printUPSInfo();

=item B<Description:>

B<printUPSInfo> prints the UPS information, i.e. manufacturer, model, and
(firmware) version to the logger as determined by a previous call of method
L<"readUPSInfo">. If these informations are unavailable, the string F<unknown>
will be used instead.

=item B<See Also:>

L<"getManufacturer">,
L<"getModel">,
L<"getVersion">,
L<"readUPSInfo">

=back

=head2 readRatingInfo

=over 8

=item B<Name:>

readRatingInfo - reading the UPS rating information

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    $ups->connect($port);
    $ups->readRatingInfo();

=item B<Description:>

B<readRatingInfo> sends the F<F> command to an UPS connected and processes the
response from the UPS yielding the rating information, i.e. the (nominal or
firmware) voltage, current, battery voltage and frequency.

=item B<See Also:>

L<"getRatingBatteryVoltage">,
L<"getRatingCurrent">,
L<"getRatingFrequency">,
L<"getRatingVoltage">,
L<"printData">,
L<"readStatus">,
L<"readUPSInfo">,
L<"sendCommand">

=back

=head2 getRatingVoltage

=over 8

=item B<Name:>

getRatingVoltage - gets the rating voltage

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

    $ups->readRatingInfo();
    $ratingVoltage = $ups->getRatingVoltage();

=item B<Description:>

B<getRatingVoltage> returns the rating voltage, i.e. the nominal output
voltage of the UPS as determined by a previous call of method
L<"readRatingInfo">. If unavailable, undef is returned.

=item B<See Also:>

L<"getRatingBatteryVoltage">,
L<"getRatingCurrent">,
L<"getRatingFrequency">,
L<"readRatingInfo">,
L<"printData">

=back

=head2 getRatingCurrent

=over 8

=item B<Name:>

getRatingCurrent - gets the rating current

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

    $ups->readRatingInfo();
    $ratingCurrent = $ups->getRatingCurrent();

=item B<Description:>

B<getRatingCurrent> returns the rating current of the UPS as determined by a
previous call of method L<"readRatingInfo">. If unavailable, undef is
returned.

=item B<See Also:>

L<"getRatingBatteryVoltage">,
L<"getRatingFrequency">,
L<"getRatingVoltage">,
L<"printData">,
L<"readRatingInfo">

=back

=head2 getRatingBatteryVoltage

=over 8

=item B<Name:>

getRatingBatteryVoltage - gets the rating battery voltage

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

    $ups->readUPSInfo();
    $ratingBatteryVoltage = $ups->getRatingBatteryVoltage();

=item B<Description:>

B<getRatingBatteryVoltage> returns the rating battery voltage, i.e. the
nominal battery voltage of the UPS as determined by a previous call of method
L<"readRatingInfo">. If unavailable, undef is returned.

=item B<See Also:>

L<"getRatingCurrent">,
L<"getRatingFrequency">,
L<"getRatingVoltage">,
L<"printData">,
L<"readRatingInfo">

=back

=head2 getRatingFrequency

=over 8

=item B<Name:>

getRatingFrequency - gets the rating current

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

    $ups->readRatingInfo();
    $ratingFrequency = $ups->getRatingFrequency();

=item B<Description:>

B<getRatingFrequency> returns the rating frequency of the UPS as determined by
a previous call of method L<"readRatingInfo">. If unavailable, undef is
returned.

=item B<See Also:>

L<"getRatingBatteryVoltage">,
L<"getRatingCurrent">,
L<"getRatingVoltage">,
L<"printData">,
L<"readRatingInfo">

=back

=head2 readStatus

=over 8

=item B<Name:>

readStatus - reading the UPS status information

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new();

    $ups->connect($port);
    $ups->readStatus();

=item B<Description:>

B<readStatus> sends the F<Q1> command to an UPS connected and processes the
response from the UPS yielding the current status information, i.e. the actual
input voltage, input fault voltage, output voltage, UPS load in % of the
maximum VA, input frequency, battery voltage, UPS temperature, the power,
battery, bypass, failure, standby, test, shutdown and beeper stati.
Additionally, it determines the minima and maxima of the input voltage and
frequency.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readRatingInfo">,
L<"readUPSInfo">,
L<"resetMinMax">,
L<"sendCommand">

=back

=head2 getInputVoltage

=over 8

=item B<Name:>

getInputVoltage - gets the current input voltage

=item B<Synopsis:>

    $ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

    $ups->readStatus();
    $inputVoltage = $ups->getInputVoltage();

=item B<Description:>

B<getInputVoltage> returns the current input voltage in Volt at the UPS as
determined by a previous call of method L<"readStatus">. If unavailable, undef
is returned.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getInputFaultVoltage

=over 8

=item B<Name:>

getInputFaultVoltage - gets the current input fault voltage

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$inputFaultVoltage = $ups->getInputFaultVoltage();

=item B<Description:>

B<getInputFaultVoltage> returns the current input fault voltage in Volt at the
UPS as determined by a previous call of method L<"readStatus">. If
unavailable, undef is returned.

For F<offline UPS models>, the purpose of the input fault voltage is to
identify a short duration voltage glitch which has caused an offline UPS to
transfer to inverter mode. If this occurs, the measured input voltage will
appear normal at the query prior to the glitch and will still appear normal
during the next query. The input fault voltage will hold the glitch voltage
until the next query. After the query, the input fault voltage will be the
same as the input voltage, until the next glitch occurs.

For F<online UPS models>, the purpose of the input fault voltage is to
identify a short duration utility failure which has caused the online UPS to
transfer to battery mode.  If this occurs, the measured input voltage will
appear normal at the query prior to the utility failure and will still appear
normal during the next query. The input fault voltage will hold the utility
failure voltage until the next query. After the query, the input fault voltage
will be the same as the input voltage, until the next utility fail occurs.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getOutputVoltage

=over 8

=item B<Name:>

getOutputVoltage - gets the current output voltage

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$outputVoltage = $ups->getOutputVoltage();

=item B<Description:>

B<getOutputVoltage> returns the current output voltage in Volt at the UPS as
determined by a previous call of method L<"readStatus">. If unavailable, undef
is returned.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getUPSLoad

=over 8

=item B<Name:>

getUPSLoad - gets the current UPS load

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$upsLoad = $ups->getUPSLoad();

=item B<Description:>

B<getUPSLoad> returns the actual UPS load in % of the maximum VA as determined
by a previous call of method L<"readStatus">. If unavailable, undef is
returned.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getInputFrequency

=over 8

=item B<Name:>

getInputFrequency - gets the current input frequency

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$inputFrequency = $ups->getInputFrequency();

=item B<Description:>

B<getInputFrequency> returns the current input frequency in Hz as determined
by a previous call of method L<"readStatus">. If unavailable, undef is
returned.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getBatteryVoltage

=over 8

=item B<Name:>

getBatteryVoltage - gets the current battery voltage

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$batteryVoltage = $ups->getBatteryVoltage();

=item B<Description:>

B<getBatteryVoltage> returns the current battery voltage in Volt as determined
by a previous call of method L<"readStatus">. If unavailable, undef is
returned.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getUPSTemperature

=over 8

=item B<Name:>

getUPSTemperature - gets the current UPS temperature

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$upsTemperature = $ups->getUPSTemperature();

=item B<Description:>

B<getUPSTemperature> returns the current UPS temperature in °C as determined
by a previous call of method L<"readStatus">. If unavailable, undef is
returned.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getPowerStatus

=over 8

=item B<Name:>

getPowerStatus - gets the current power status

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$powerStatus = $ups->getPowerStatus();

=item B<Description:>

B<getPowerStatus> returns the current power status of the UPS, i.e. bit 7 of
the status value supplied by the F<Q1> command, as determined by a previous
call of method L<"readStatus">. A value of 1 indicates power failure, a value
of 0 that everything is OK.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getBatteryStatus

=over 8

=item B<Name:>

getBatteryStatus - gets the current battery status

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$batteryStatus = $ups->getBatteryStatus();

=item B<Description:>

B<getBatteryStatus> returns the current battery status of the UPS, i.e. bit 6
of the status value supplied by the F<Q1> command, as determined by a previous
call of method L<"readStatus">. A value of 1 indicates a low battery, a value
of 0 that everything is OK.

=item B<See Also:>

L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getBypassStatus

=over 8

=item B<Name:>

getBypassStatus - gets the current bypass status

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$BypassStatus = $ups->getBypassStatus();

=item B<Description:>

B<getBypassStatus> returns the current bypass status of the UPS, i.e. bit 5 of
the status value supplied by the F<Q1> command, as determined by a previous
call of method L<"readStatus">. A value of 1 indicates that a bypass/boost or
a buck are active, a value of 0 that they are not.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getFailedStatus

=over 8

=item B<Name:>

getFailedStatus - gets the current failure status

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$failedStatus = $ups->getFailedStatus();

=item B<Description:>

B<getFailedStatus> returns the current failure status of the UPS, i.e. bit 4
of the status value supplied by the F<Q1> command, as determined by a previous
call of method L<"readStatus">. A value of 1 indicates failure of the UPS, a
value of 0 that everything is OK.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getStandbyStatus

=over 8

=item B<Name:>

getStandbyStatus - gets the current standby status

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$standbyStatus = $ups->getStandbyStatus();

=item B<Description:>

B<getStandbyStatus> returns the current standby status of the UPS, i.e. bit 3
of the status value supplied by the F<Q1> command, as determined by a previous
call of method L<"readStatus">. A value of 1 indicates that the UPS is in
standby, a value of 0 that the UPS is online.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getTestStatus

=over 8

=item B<Name:>

getTestStatus - gets the current test status

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$testStatus = $ups->getTestStatus();

=item B<Description:>

B<getTestStatus> returns the current test status of the UPS, i.e. bit 2 of the
status value supplied by the F<Q1> command, as determined by a previous call
of method L<"readStatus">. A value of 1 indicates that there is a test in
progress, a value of 0 that no test is currently performed.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getShutdownStatus

=over 8

=item B<Name:>

getShutdownStatus - gets the current shutdown status

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$shutdownStatus = $ups->getShutdownStatus();

=item B<Description:>

B<getShutdownStatus> returns the current shutdown status of the UPS, i.e. bit
1 of the status value supplied by the "Q1" command, as determined by a
previous call of method L<"readStatus">. A value of 1 indicates that there is
a shutdown active, a value of 0 that there is no shutdown performed.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 getBeeperStatus

=over 8

=item B<Name:>

getBeeperStatus - gets the current beeper status

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$beeperStatus = $ups->getBeeperStatus();

=item B<Description:>

B<getBeeperStatus> returns the current shutdown status of the UPS, i.e. bit 0
of the status value supplied by the F<Q1> command, as determined by a previous
call of method L<"readStatus">. A value of 1 indicates that the beeper is on,
a value of 0 that it is not.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 resetMinMax

=over 8

=item B<Name:>

resetMinMax - resets the minima and maxima of the input voltage and frequency

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new();

	$ups->resetMinMax();

=item B<Description:>

B<resetMinMax> resets the minima and maxima of the input voltage and
frequency.

=item B<See Also:>

L<"printMinMax">,
L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,

=back

=head2 printMinMax

=over 8

=item B<Name:>

printMinMax - prints the minima and maxima of the input voltage and frequency

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();

	$ups->printMinMax();            # the same as $ups->printMinMax("syslog");
	$ups->printMinMax("debug");
	$ups->printMinMax("info");
	$ups->printMinMax("error");
	$ups->printMinMax("fatal");
	$ups->printMinMax("syslog");

=item B<Description:>

B<printMinMax> prints a string containing the minima and maxima of the input
voltage and frequency as determined by a previous call of method
L<"readStatus"> to the logger or to syslog.

=item B<Arguments:>

=over 8

=item C<< $level >>

string; defines the logging level ("debug", "info", "error", "fatal" or
"syslog"; if omitted, the minima and maxima are written to syslog.

=back

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"resetMinMax">

=back

=head2 printData

=over 8

=item B<Name:>

printData - printing the comparison between the rating info and the current
UPS status

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readRatingsInfo();
	$ups->readStatus();

	$ups->printData();

=item B<Description:>

B<printData> prints the comparison between the rating info (firmware data) and
the current UPS status to the log file, if available, to STDERR, otherwise, as
determined by previous calls of the methods L<"readRatingInfo"> and
L<"readStatus">.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"readUPSInfo">,
L<"resetMinMax">

=back

=head2 printStatus

=over 8

=item B<Name:>

printStatus - printing status flags in a human readable format

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$ups->printStatus($fh);

	$ups->printStatus();

=item B<Description:>

B<printStatus> prints the status flags as determined by a previous call of
method L<"readStatus"> to the log file, if available, to STDERR, otherwise, in
a human readable format.

=item B<See Also:>

L<"getBatteryStatus">,
L<"getBatteryVoltage">,
L<"getBeeperStatus">,
L<"getBypassStatus">,
L<"getFailedStatus">,
L<"getInputFaultVoltage">,
L<"getInputFrequency">,
L<"getInputVoltage">,
L<"printMinMax">,
L<"getOutputVoltage">,
L<"getPowerStatus">,
L<"getShutdownStatus">,
L<"getStandbyStatus">,
L<"getTestStatus">,
L<"getUPSLoad">,
L<"getUPSTemperature">,
L<"printData">,
L<"printStatus">,
L<"readStatus">,
L<"readUPSInfo">,
L<"resetMinMax">

=back

=head2 toggleBeeper

=over 8

=item B<Name:>

toggleBeeper - toggles the beeper

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$ups->printStatus();

	$ups->toggleBeeper();

    $ups->readStatus();
    print STDOUT $ups->getBeeperStatus(), "\n";

=item B<Description:>

B<toggleBeeper> sends the F<Q> command to the UPS connected, i.e. toggles the
beeper's state from OFF to ON and vice versa.

=item B<See Also:>

L<"getBeeperStatus">,
L<"printStatus">,
L<"readStatus">

=back

=head2 testUPS

=over 8

=item B<Name:>

testUPS - tests the UPS

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$ups->printStatus();

	$ups->testUPS();

    $ups->readStatus();
    print STDOUT $ups->getTestStatus(), "\n";

=item B<Description:>

B<testUPS> sends the F<T> command to the UPS connected, i.e. causes the UPS
to perform a 10 second test.

If battery low occurs during testing, UPS will return to utility immediately.

=item B<See Also:>

L<"cancelTest">,
L<"getTestStatus">,
L<"printStatus">,
L<"readStatus">,
L<"testUPSBatteryLow">,
L<"testUPSPeriod">

=back

=head2 testUPSBatteryLow

=over 8

=item B<Name:>

testUPSBatteryLow - tests the UPS

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$ups->printStatus();

	$ups->testUPSBatteryLow();

    $ups->readStatus();
    print STDOUT $ups->getTestStatus(), "\n";

=item B<Description:>

B<testUPS> sends the F<TL> command to the UPS connected, i.e. causes the UPS
to perform a test until battery low occurs.

=item B<See Also:>

L<"cancelTest">,
L<"getTestStatus">,
L<"printStatus">,
L<"readStatus">,
L<"testUPS">,
L<"testUPSPeriod">

=back

=head2 testUPSPeriod

=over 8

=item B<Name:>

testUPSPeriod - tests the UPS for a period of time

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$ups->printStatus();

    $n = 9;
	$ups->testUPSPeriod($n);

    $ups->readStatus();
    print STDOUT $ups->getTestStatus(), "\n";

=item B<Description:>

B<testUPSPeriod> sends the F<T$n> command to the UPS connected, i.e. causes the
UPS to perform a test for the period of time F<$n> in minutes.

If battery low occurs during testing, the UPS returns to utility immediately.

=item B<Arguments:>

=over 8

=item C<< $n >>

required; natural number less than 100; the testing period in minutes.

=back

=item B<See Also:>

L<"cancelTest">,
L<"getTestStatus">,
L<"printStatus">,
L<"readStatus">,
L<"testUPS">,
L<"testUPSBatteryLow">

=back

=head2 cancelTest

=over 8

=item B<Name:>

cancelTest - cancels UPS tests

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$ups->printStatus();

	$ups->testUPSPeriod(50);
	$ups->cancelTest();

    $ups->readStatus();
    print STDOUT $ups->getTestStatus(), "\n";

=item B<Description:>

B<cancelTest> sends the F<CT> command to the UPS connected, i.e. causes the
UPS to cancel any test activity and to connect the output to utility
immediately.

=item B<See Also:>

L<"getTestStatus">,
L<"printStatus">,
L<"readStatus">,
L<"testUPS">,
L<"testUPSBatteryLow">,
L<"testUPSPeriod">

=back

=head2 shutdownUPS

=over 8

=item B<Name:>

shutdownUPS - shuts the UPS down in a period of time

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$ups->printStatus();

    $time = 9;
	$ups->shutdownUPS($n);

    $ups->readStatus();
    print STDOUT $ups->getShutdownStatus(), "\n";

=item B<Description:>

B<shutdownUPS> sends the F<S$time> command to the UPS connected, i.e. causes
the UPS to perform a shutdown in a certain period of time F<$time> in minutes.

=item B<Arguments:>

=over 8

=item C<< $time >>

required; floating number greater than 0 and less than 10; the period in
minutes, when the UPS will shutdown.

=back

=item B<See Also:>

L<"cancelShutdown">,
L<"getShutdownStatus">,
L<"printStatus">,
L<"readStatus">,
L<"shutdownRestore">

=back

=head2 shutdownRestore

=over 8

=item B<Name:>

shutdownRestore - shuts the UPS down in a period of time and restarts it again

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$ups->printStatus();

    $shutdown = 9;
    $restore  = 19;
	$ups->shutdownRestore($shutdown, $restore);

    $ups->readStatus();
    print STDOUT $ups->getShutdownStatus(), "\n";

=item B<Description:>

B<shutdownRestore> sends the F<S${shutdown}R${retore}> command to the UPS
connected, i.e. causes the UPS to perform a shutdown in a certain period of
time F<$shutdown> in minutes and restores it after F<$restore> minutes.

=item B<Arguments:>

=over 8

=item C<< $shutdown >>

required; floating number greater than 0 and less than 10; the period in
minutes, when the UPS will shutdown.

=item C<< $restore >>

required; floating number greater than 0 and less than 1000; the period in
minutes, when the UPS will be restored again.

=back

=item B<See Also:>

L<"cancelShutdown">,
L<"getShutdownStatus">,
L<"printStatus">,
L<"readStatus">,
L<"shutdownUPS">

=back

=head2 cancelShutdown

=over 8

=item B<Name:>

cancelShutdown - cancels UPS shutdown processes

=item B<Synopsis:>

	$ups = Hardware::UPS::Perl::Driver::Megatec->new($port);

	$ups->readStatus();
	$ups->printStatus();

	$ups->shutdownUPS(50);
	$ups->cancelShutdown();

    $ups->readStatus();
    print STDOUT $ups->getShutdownStatus(), "\n";

=item B<Description:>

B<cancelShutdown> sends the F<C> command to the UPS connected, i.e. causes the
UPS to cancel any shutdown activity.

If the UPS is in shutdown waiting state, the shutdown command is cancelled.

If UPS is in restore waiting state, the UPS output is turned on, but the UPS
must be hold off at least 10 seconds (if utility is present).

=item B<See Also:>

L<"getShutdownStatus">,
L<"printStatus">,
L<"readStatus">,
L<"shutdownUPS">,
L<"shutdownRestore">

=back

=head1 SEE ALSO

Hardware::UPS::Perl::Connection(3pm),
Hardware::UPS::Perl::Connection::Net(3pm),
Hardware::UPS::Perl::Connection::Serial(3pm),
Hardware::UPS::Perl::Constants(3pm),
Hardware::UPS::Perl::Driver(3pm),
Hardware::UPS::Perl::General(3pm),
Hardware::UPS::Perl::Logging(3pm),
Hardware::UPS::Perl::PID(3pm),
Hardware::UPS::Perl::Utils(3pm)

=head1 NOTES

B<Hardware::UPS::Perl::Driver::Megatec> was inspired by the B<usv.pl> program
by Bernd Holzhauer, E<lt>www.cc-c.deE<gt>. The latest version of this program
can be obtained from

    http://www.cc-c.de/german/linux/linux_usv.php

Another great resource was the B<Network UPS Tools> site, which can be found
at

    http://www.networkupstools.org

B<Hardware::UPS::Perl::Driver::Megatec> was developed using B<perl 5.8.8> on a
B<SuSE 10.1> Linux distribution.

=head1 BUGS

There are plenty of them for sure. Maybe the embedded pod documentation has to
be revised a little bit.

Suggestions to improve B<Hardware::UPS::Perl::Driver::Megatec> are welcome,
though due to the lack of time it might take a while to incorporate them.

=head1 AUTHOR

Copyright (c) 2007 by Christian Reile, E<lt>Christian.Reile@t-online.deE<gt>.
All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. For further licensing
details, please see the file COPYING in the distribution.

=cut
