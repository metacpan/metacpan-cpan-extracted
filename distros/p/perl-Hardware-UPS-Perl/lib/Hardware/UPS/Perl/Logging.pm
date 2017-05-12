package Hardware::UPS::Perl::Logging;

#==============================================================================
# package description:
#==============================================================================
# This package supplies a set of methods to log messages to a file. For a
# detailed description see the pod documentation included at the end of this
# file.
#
# List of public methods:
# -----------------------
#   new                     - initializing a Hardware::UPS::Perl logging object
#   getErrorMessage         - getting internal error messages
#   getHandle               - getting the filehandle of the current log file 
#   getLogFile              - getting the current log file
#   getRotationPeriod       - getting the current period used for rotating
#                             log files
#   getRotationScheme       - getting the current scheme used for rotating
#                             log files
#   getRotationSize         - getting the current size used for rotating
#                             log files
#   rotate                  - forces rotation of the log file
#   debug                   - printing debug messages to log file
#   info                    - printing normal messages to log file
#   error                   - printing error messages to log file
#   fatal                   - printing fatal error messages to log file and die
#   print                   - printing any message to the log file
#   write                   - printing a formatted message to the log file
#   syslog                  - printing message to syslog
#   setMailTo               - setting the current mail recipient
#   getMailTo               - getting the current mail recipient
#   sendmail                - sending email
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
# Revision        : $Revision: 1.9 $
# Author          : $Author: creile $
# Last Modified On: $Date: 2007/04/14 09:37:26 $
# Status          : $State: Exp $
#------------------------------------------------------------------------------
# Modifications   :
#------------------------------------------------------------------------------
#
#   $Log: Logging.pm,v $
#   Revision 1.9  2007/04/14 09:37:26  creile
#   documentation update.
#
#   Revision 1.8  2007/04/07 15:16:38  creile
#   adaptations to "best practices" style;
#   update of documentation.
#
#   Revision 1.7  2007/03/13 17:21:20  creile
#   usage of Perl pragma constant for some package variables;
#   options as anonymous hashes;
#   method write() revised.
#
#   Revision 1.6  2007/03/03 21:18:32  creile
#   new variable $UPSERROR added;
#   adaptations to revised Constants.pm;
#   "return undef" replaced by "return";
#   new method write() for formatted output added.
#
#   Revision 1.5  2007/02/25 17:07:14  creile
#   option handling redesigned.
#
#   Revision 1.4  2007/02/05 20:34:31  creile
#   bug fix creating symlink of log file;
#   pod documentation revised.
#
#   Revision 1.3  2007/02/04 14:03:50  creile
#   bug fix in pod documentation.
#
#   Revision 1.2  2007/02/03 20:49:23  creile
#   support for syslog and sending mail added;
#   different rotation schemes introduced (naone, daily, period
#   and size);
#   private methods _rotate() and _setLogFile() revised;
#   log file is truncated now, if it already exists;
#   update of documentation.
#
#   Revision 1.1  2007/01/30 23:03:19  creile
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

    $VERSION = sprintf( "%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/ );

    @ISA     = qw();

}

#==============================================================================
# end of module preamble
#==============================================================================

#==============================================================================
# packages required:
#------------------------------------------------------------------------------
#
#   Carp                            - warn of errors (from perspective of
#                                     caller)
#   constant                        - Perl pragma to declare constants
#   Date::Format                    - Date formating subroutines
#   Fcntl                           - load the C Fcntl.h defines
#   File::Basename                  - parse file paths into directory, filename
#                                     and suffix
#   File::Find                      - traverse a directory tree
#   FileHandle                      - supply object methods for filehandles
#   Mail::Send                      - simple electronic mail interface
#   Sys::Syslog                     - Perl interface to the UNIX syslog(3)
#                                     calls
#   Time::HiRes                     - high resolution alarm, sleep,
#                                     gettimeofday, interval timers
#
#   Hardware::UPS::Perl::Constants  - importing Hardware::UPS::Perl constants
#   Hardware::UPS::Perl::General    - importing Hardware::UPS::Perl variables
#                                     and functions for scripts
#   Hardware::UPS::Perl::Utils      - importing Hardware::UPS::Perl utility
#                                     functions for packages
#
#==============================================================================

use Carp;
use Date::Format;
use Fcntl;
use File::Basename;
use File::Find;
use FileHandle;
use Mail::Send;
use Sys::Syslog ();

use Time::HiRes qw(
    time
    setitimer
    ITIMER_REAL
);

use Hardware::UPS::Perl::Constants qw(
    UPSHOSTNAME
    UPSMAILTO
    UPSSCRIPT
);
use Hardware::UPS::Perl::General qw(
    $UPSERROR
);
use Hardware::UPS::Perl::Utils qw(
);

#==============================================================================
# defining user invisible package variables and constants:
#------------------------------------------------------------------------------
# 
#   %ROTATION_SCHEME                - the table of rotation schemes
#   ROTATION_PERIOD                 - the default period to rotate log files
#                                     in seconds
#   ROTATION_SIZE                   - the default size to rotate log files in
#                                     bytes
#   ALARM_PERIOD                    - the period to trigger the alarm signal
#                                     in seconds
# 
#==============================================================================

my %ROTATION_SCHEME = (
    none    => 0,
    daily   => 1,
    period  => 2,
    size    => 3,
);

use constant ROTATION_PERIOD => 60 * 60 * 24;
use constant ROTATION_SIZE   => 1024 * 1024;     
use constant ALARM_PERIOD    => 60;

#==============================================================================
# public methods:
#==============================================================================

sub new {

    # public method to construct a logging object
    #
    # parameters: $class   (input) - class
    #             $options (input) - anonymous hash; options
    #
    # The following option keys are recognized:
    #
    #   File    ($) - the log file; optional;
    #   MailTo  ($) - the mail recipient; optional; default: UPSMAILTO
    #   Period  ($) - the rotation period in minutes,
    #                 implies Scheme = "period"; optional;
    #                 default: ROTATION_PERIOD
    #   Scheme  ($) - the rotation scheme:
    #                 Scheme = "none"  : no rotation (default);
    #                          "daily" : rotation on a daily basis;
    #                          "period": periodically rotation;
    #                          "size"  : rotation based on size;
    #                 optional;
    #   Size    ($) - the rotation size in megabytes, implies Scheme = "size";
    #                 optional; default: ROTATION_SIZE.

    # input as hidden local variables
    my $class   = shift;
    my $options = @_ ? shift : {};

    # hidden local variables
    my $self    = {};       # referent to be blessed
    my $refType;            # the reference type
    my %processOption;      # the action table to process options
    my $option;             # an option
    my $arg;                # an option argument
    my $logFile;            # the name of the log file
    my $mailTo;             # the mail recipient
    my $scheme;             # the rotation scheme
    my $period;             # the rotation period
    my $size;               # the rotation size

    # blessing logging object
    bless $self, $class;

    # checking options
    $refType = ref($options);
    if ($refType ne 'HASH') {
        error("not a hash reference -- <$refType>");
    }

    # processing options, starting with defaults
    $mailTo = UPSMAILTO;
    $period = ROTATION_PERIOD;
    $scheme = "none";
    $size   = ROTATION_SIZE;

    %processOption = (
        File    =>  sub { # the name of the log file
                        $logFile = shift;
                    },  
        MailTo  =>  sub { # the mail recipient
                        $mailTo  = shift;
                    },  
        Period  =>  sub { # the rotating period in minutes
                        my $arg = shift;
                        
                        if (exists $options->{Size}) {
                            Hardware::UPS::Perl::Utils::error(
                                "unexpected option -- Period"
                            );
                        }

                        if ($arg =~ /\d+/ and ($arg > 0)) {
                            $period = $arg * 60;
                        }
                        else {
                            Hardware::UPS::Perl::Utils::error(
                                "not a natural number -- $arg"
                            );
                        }

                        if (!exists $options->{Scheme}) {
                            $scheme = "period"
                        }  

                    },
        Scheme  =>  sub { # the rotation scheme: none, daily, period, size 
                        my $arg = shift;

                        if (exists $ROTATION_SCHEME{$arg}) {
                            $scheme = $arg;
                        }
                        else {
                            Hardware::UPS::Perl::Utils::error(
                                "unknown rotation scheme -- $arg"
                            );
                        }

                    },
        Size    =>  sub { # the rotating size in megabytes 
                        my $arg = shift;

                        if ( exists $options->{Period}) {
                            Hardware::UPS::Perl::Utils::error(
                                "unexpected option -- Size"
                            );
                        }

                        if ($arg =~ /\d+/ and ($arg > 0)) {
                            $size = $arg * ROTATION_SIZE;
                        }
                        else {
                            Hardware::UPS::Perl::Utils::error(
                                "not a natural number -- $arg"
                            );
                        }
                        
                        if (!exists $options->{Scheme}) {
                            $scheme = "size";
                        }
                    },  
    );

    while (($option, $arg) = each %{$options}) {
        if (exists $processOption{$option}) {
            $processOption{$option}->($arg);
        }
        else {
            # default: option unknown
            Hardware::UPS::Perl::Utils::error("option unknown -- $option");
        }
    }

    # initializing
    $self->{errorMessage} = q{};
    $self->setMailTo($mailTo);

    if (defined $logFile) {

        if (ref($logFile) eq 'GLOB') {

            # we have a GLOB to pass all output to
            $self->{_fileBase} = undef;

            $self->_setRotationScheme("none");
            $self->_setLogFile();

            $self->{handle} = $logFile;

        }
        else {

            # we have a real log file
            $self->{_fileBase} = $logFile;

            $self->_setRotationPeriod($period);
            $self->_setRotationScheme($scheme);
            $self->_setRotationSize($size);

            $self->_setLogFile(time);

            # opening file
            $self->_open($self->getLogFile())
                or  do {
                        $UPSERROR = $self->getErrorMessage();
                        return;
                    };

            # setting up timer for rotation and starting it, if we have
            # rotation enabled
            if ($ROTATION_SCHEME{$scheme}) {

                if ($scheme eq "period") {
                    $self->{_alarmPeriod} = $period;
                }
                else {
                    $self->{_alarmPeriod} = ALARM_PERIOD;
                }

                $SIG{ALRM} = sub {
                    # rotate
                    $self->_rotate();
                    # setting up the alarm again
                    setitimer(ITIMER_REAL, $self->{_alarmPeriod});
                };

                setitimer(ITIMER_REAL, $self->{_alarmPeriod});

            }

        }

    }
    else {

        # no log file supplied, passing all output to STDERR
        $self->{_fileBase} = undef;

        $self->_setRotationScheme("none");
        $self->_setLogFile();

        $self->{handle} = \*STDERR;

    }

    # returning blessed logging object
    return $self;

} # end of public method "new"

sub DESTROY {

    # the destructor will close the current log file
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self = shift;

    # closing log file
    $self->_close();

} # end of the destructor

sub getErrorMessage {

    # public method to get the current error message
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self = shift;

    # getting the error message
    if (exists $self->{errorMessage}) {
        return $self->{errorMessage};
    } else {
        return;
    }

} # end of public method "getErrorMessage"

sub getHandle {

    # public method to get the current log file handle
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self = shift;

    # getting handle
    if (exists $self->{handle}) {
        return $self->{handle};
    } else {
        return;
    }

} # end of public method "getHandle"

sub getLogFile {

    # public method to get the current log file
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self = shift;

    # getting log file
    if (exists $self->{logfile}) {
        return $self->{logfile};
    } else {
        return;
    }

} # end of public method "getLogFile"

sub getRotationPeriod {

    # public method to get the current rotation period
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self = shift;

    # getting rotation period
    if (exists $self->{period} and defined $self->{period}) {
        return $self->{period} / 60;
    } else {
        return;
    }

} # end of public method "getRotationPeriod"

sub getRotationSize {

    # public method to get the current rotation size in megabytes
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self = shift;

    # getting rotation size
    if (exists $self->{size} and defined $self->{size}) {
        return $self->{size} / ROTATION_SIZE;
    } else {
        return;
    }

} # end of public method "getRotationSize"

sub getRotationScheme {

    # public method to get the current rotation scheme
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self = shift;

    # getting rotation scheme
    if (exists $self->{scheme}) {
        return $self->{scheme};
    } else {
        return;
    }

} # end of public method "getRotationScheme"

sub debug {

    # public method to write debug messages to the log file
    #
    # parameters: $self    (input) - referent to a logging object
    #             $message (input) - debug message

    # input as hidden local variable
    my $self    = shift;
    my $message = shift;

    # printing debug message to log file
    return $self->print("DEBUG: $message\n");

} # end of public method "debug"

sub info {

    # public method to write normal messages to the log file
    #
    # parameters: $self    (input) - referent to a logging object
    #             $message (input) - normal log message

    # input as hidden local variable
    my $self    = shift;
    my $message = shift;

    # writing info message to log file
    return $self->print("INFO : $message\n");

} # end of public method "info"

sub error {

    # public method to write non-fatal error messages to the log file
    #
    # parameters: $self    (input) - referent to a logging object
    #             $message (input) - error message

    # input as hidden local variable
    my $self    = shift;
    my $message = shift;

    # printing error message to log file
    return $self->print("ERROR: $message\n");

} # end of public method "error"

sub fatal {

    # public method to write an error messages to the log file and dieing
    #
    # parameters: $self    (input) - referent to a logging object
    #             $message (input) - fatal error message

    # input as hidden local variable
    my $self    = shift;
    my $message = shift;

    # printing fatal error message to log file
    $self->print("FATAL: $message\n");

    # time to say good-bye ...
    croak("FATAL: $message");

} # end of public method "fatal"

sub print {

    # public method to print messages to the log file
    #
    # parameters: $self    (input) - referent to a logging object
    #             $message (input) - the log message

    # input as hidden local variable
    my $self    = shift;
    my $message = shift;

    # hidden local variables
    my $scheme;             # the numerical rotation scheme
    my $date;               # the current date
    my $alarm;              # time left of the alarm

    # getting the rotation scheme
    $scheme = $self->getRotationScheme();
    if (defined $scheme) {
        $scheme = $ROTATION_SCHEME{$scheme};
    } else {
        $scheme = 0;
    }

    # writing log message
    my $fh = $self->getHandle();

    if (defined $fh and (ref($fh) eq 'FileHandle') or (ref($fh) eq 'GLOB')) {

        # getting date
        $date = time2str("%b %d %T", time);

        # blocking rotation
        if ($scheme) {
            $alarm = setitimer(ITIMER_REAL, 0);
            if (!$alarm) {
                $alarm = $self->{_alarmPeriod};
            }
        }

        # writing message to log file
        $fh->print("$date: ".UPSSCRIPT.": $message");

        # unblocking rotation
        if ($scheme) {
            setitimer(ITIMER_REAL, $alarm);
        }

        return 1;

    } else {

        $self->{errorMessage} = "log file unavailable";
        return 0;

    }

} # end of public method "print"

sub write {

    # public method to write formatted messages to the log file
    #
    # parameters: $self    (input) - referent to a logging object
    #             $options (input) - anonymous hash; options
    #
    # The following option keys are recognized:
    #
    #   Format      ($) - string; the format to use
    #   Type        ($) - string; the information type;
    #                     type = debug: prepending "DEBUG:";
    #                            info : prepending "INFO :";
    #                                   this is the default;
    #                            error: prepending "ERROR:";
    #                            fatal: prepending "FATAL:";
    #   Arguments   (%) - hash reference; the arguments used in the format

    # input as hidden local variables
    my $self    = shift;
    my $options = @_ ? shift : {};

    # hidden local variables
    my $refType;            # a reference type
    my $formatString;       # the format
    my $declaration;        # the declaration part of the format
    my @formatList;         # the form list
    my $formatName;         # the name of the format
    my $arguments = {};     # the arguments of the format
    my $type;               # the output type
    my %processType;        # action table to process the type
    my $fatalFlag;          # the flag indicating a fatal error
    my $scheme;             # the numerical rotation scheme
    my $logDate;            # the current date
    my $alarm;              # time left of the alarm

    # checking options
    $refType = ref($options);
    if ($refType ne 'HASH') {
        Hardware::UPS::Perl::Utils::error("not a hash reference -- <$refType>");
    }

    # format
    $formatString = delete $options->{Format};

    if (!defined $formatString) {
        Hardware::UPS::Perl::Utils::error("no format available");
    }

    # setting up the actio  table to process the type
    %processType = (
        debug   =>  sub { $type = uc($type)     ; $fatalFlag = 0; },
        error   =>  sub { $type = uc($type)     ; $fatalFlag = 0; },
        fatal   =>  sub { $type = uc($type)     ; $fatalFlag = 1; },
        info    =>  sub { $type = uc($type).q{ }; $fatalFlag = 0; },
        none    =>  sub { $type = q{}           ; $fatalFlag = 0; },
    );

    # the type
    $type = delete $options->{Type};

    if (defined $type) {
        if (exists $processType{ lc($type) }) {
            $processType{ lc($type) }->();
        }
        else {
            # default: type unknown
            Hardware::UPS::Perl::Utils::error("unexpected type -- $type")
        }
    }
    else {
        $type      = "INFO ";
        $fatalFlag = 0;
    }


    # the arguments
    $arguments = delete $options->{Arguments};

    if (!defined $arguments) {
        Hardware::UPS::Perl::Utils::error("no arguments available");
    }

    # getting the rotation scheme
    $scheme = $self->getRotationScheme();
    if (defined $scheme) {
        $scheme = $ROTATION_SCHEME{$scheme};
    } else {
        $scheme = 0;
    }

    # writing log message
    my $fh = $self->getHandle();

    if (defined $fh and (ref($fh) eq 'FileHandle') or (ref($fh) eq 'GLOB')) {

        if ($type) {

            # getting date
            $logDate = time2str("%b %d %T", time);

            # prepending logging date and scriptname to format
            @formatList = split(/\n/, $formatString);
            $declaration = shift(@formatList);
            pop(@formatList);

            foreach my $line (@formatList) {
                if ($line !~ m{^(\s*)\$}xms) {
                    $line = $logDate.q{: }.UPSSCRIPT.q{: }.$type.q{: }.$line;
                }
            }

            unshift(@formatList, $declaration);
            push   (@formatList, q{.});

            $formatString = join("\n", @formatList);

        }
        else {

            # no prepending
            @formatList  = split(/\n/, $formatString);
            $declaration = shift(@formatList);

        }

        # the format name
        $formatName = (split(/\s+/, $declaration))[1];

        # evaluating format
        {
            no strict;
            no warnings 'redefine';

            EVAL_FORMAT:
            while (($var, $value) = each %{$arguments}) {
                $$var = $value;
            }

            eval $formatString;
            if ($@) {
                $self->{errorMessage} = "format evaluation failed -- $@";
                return 0;
            }
        }

        # blocking rotation
        if ($scheme) {
            $alarm = setitimer(ITIMER_REAL, 0);
            if (!$alarm) {
                $alarm = $self->{_alarmPeriod};
            }
        }

        # writing message to log file
        my $oldFH = select($fh);
        $~ = $formatName;
        write;
        select($oldFH);

        # unblocking rotation
        if ($scheme) {
            setitimer(ITIMER_REAL, $alarm);
        }

        if ($fatalFlag) {
            $self->fatal("exiting ...");
        }

        return 1;

    } else {

        $self->{errorMessage} = "log file unavailable";
        return 0;

    }

} # end of public method "write"

sub syslog {

    # public method to print messages to syslog
    #
    # parameters: $self    (input) - referent to a logging object
    #             $options (input) - anonymous hash; options
    #
    # The following option keys are recognized:
    #
    #   level   ($) - the syslog level
    #   message ($) - the message

    # input as hidden local variables
    my $self    = shift;
    my $options = @_ ? shift : {};

    # hidden local variables
    my $refType;            # a reference type
    my $option;             # an option
    my $arg;                # an option argument
    my $message;            # the message
    my $level;              # the syslog level log 

    # checking options
    $refType = ref($options);

    if (!$refType) {

        # just a message
        $level   = "LOG_DEBUG";
        $message = $options;

    }
    elsif ($refType eq 'HASH') {

        # processing options, starting with defaults
        $level   = "LOG_DEBUG";
        $message = q{};

        while (($option, $arg) = each %{$options}) {
            for ($option) {
                # the syslog level
                /^level$/   &&  do {
                                    $level   = $arg;
                                  last;
                                };  
                # the message
                /^message$/ &&  do {
                                    $message = $arg;
                                  last;
                                };  
                # default: error option unknown
                Hardware::UPS::Perl::Utils::error("option unknown -- $option");
            }
        }

    }
    else {
        Hardware::UPS::Perl::Utils::error("not a hash reference -- <$refType>")
    }

    # writing message to syslog
    Sys::Syslog::openlog(UPSSCRIPT, "cons.pid", "UPS");
    Sys::Syslog::syslog($level, $message);
    Sys::Syslog::closelog;

    return 1;

} # end of public method "syslog"

sub setMailTo {

    # public method to set the mail recipient for e-mails
    #
    # parameters: $self   (input) - referent to a logging object
    #             $mailto (input) - the mail recipient

    # input as hidden local variables
    my $self   = shift;
    my $mailto = shift;

    # getting old mail recipient
    my $oldMailTo = $self->getMailTo();

    # setting new mail recipient
    $self->{mailto} = $mailto;

    # returning old mail recipient
    return $oldMailTo;

} # end of public method "setMailTo"

sub getMailTo {

    # public method to get the current mail recipient
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self = shift;

    # getting mail recipient
    if (exists $self->{mailto}) {
        return $self->{mailto};
    } else {
        return;
    }

} # end of public method "getMailTo"

sub sendmail {

    # public method to send a mail to the current mail recipient
    #
    # parameters: $self    (input) - referent to a logging object
    #             $options (input) - anonymous hash; options
    #
    # The following option keys are recognized:
    #
    #   MailTo  ($) - the mail recipient; optional
    #   Message ($) - the message; optional
    #   Subject ($) - the subject; optional

    # input as hidden local variables
    my $self    = shift;
    my $options = @_ ? shift : {};

    # hidden local variables
    my $refType;            # a reference type
    my %processOption;      # action table to process options
    my $option;             # an option
    my $arg;                # an option argument
    my $mailTo  = q{};      # the mail recipient
    my $subject = q{};      # the mail subject
    my $message = q{};      # the mail message
    my $mail;               # the mail object
    my $mailer_fh;          # the mailer

    # checking options
    $refType = ref($options);
    if ($refType ne 'HASH') {
        Hardware::UPS::Perl::Utils::error("not a hash reference -- <$refType>");
    }

    # setting up the action table
    %processOption = (
        MailTo  =>  sub { # the mail recipient
                        $mailTo  = shift;
                    },  
        Message =>  sub { # the mail message
                        $message = shift;
                    },  
        Subject =>  sub { # the mail subject
                        $subject = shift;
                    },  
    );

    # processing options
    PROCESS_OPTIONS:
    while (($option, $arg) = each %{$options}) {
        if (exists $processOption{$option}) {
            $processOption{$option}->($arg);
        }
        else {
            # default: option unknown
            Hardware::UPS::Perl::Utils::error("option unknown -- $option");
        }
    }

    # checking mail recipient
    if (!$mailTo) {
        $mailTo = $self->getMailTo();
        if (!(defined $mailTo and $mailTo)) {
            $self->{errorMessage} = "no mail recipient available";
            return 0;
        }
    }
    
    # sending mail
    if (defined $subject and $subject) {
        $subject =  UPSSCRIPT." at ".UPSHOSTNAME.": ".$subject;
    } else {
        $subject =  UPSSCRIPT." at ".UPSHOSTNAME;
    }

    $mail = Mail::Send->new(
        Subject => $subject,
        To      => $mailTo ,
    );

    $mailer_fh = $mail->open("sendmail")
        or  do {
                $self->{errorMessage} = "opening sendmail failed";
                return 0;
            };

    if ($message) {
        print $mailer_fh "$message\n";
    } else {
        print $mailer_fh "event occured at ".scalar(localtime())."\n";
    }

    $mailer_fh->close
        or  do {
                $self->{errorMessage} = "sending mail $subject to $mailTo failed";
                return 0;
            };

    return 1;

} # end of public method "sendmail"

sub rotate {

    # public method to force rotation of the log file
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self    = shift;

    # closing log file
    if ($self->_close()) {

        # setting new log file
        $self->_setLogFile(time);

        # opening new log file
        return $self->_open($self->getLogFile());

    }
    else {
        
        return 1;

    }

} # end of public method "rotate"

#==============================================================================
# private methods:
#==============================================================================

sub _open {

    # private method to open a log file
    #
    # parameters: $self    (input) - referent to a logging object
    #             $logFile (input) - string, the log file

    # input as hidden local variable
    my $self    = shift;
    my $logFile = shift;

    # hidden local variable
    my $log_fh;            # the log file filehandle         

    # already open ?
    if ($self->_opened($logFile)) {
        $self->{errorMessage} = "log file $logFile already open";
        return 0;
    }

    # opening log file filehandle
    if (defined $logFile) {
        $log_fh = new FileHandle $logFile, O_CREAT| O_RDWR | O_TRUNC;
    }
    else {
        $self->{errorMessage} = "invalid log file $logFile";
        return 0;
    }

    if (!defined $log_fh) {
        $self->{errorMessage} = "cannot open log file $logFile -- $!";
        return 0;
    }

    $log_fh->autoflush();

    # creating file link
    my $logFileLink = $self->{_fileBase};

    if ($logFileLink ne $logFile) {

        unlink($logFileLink) if ( -w $logFileLink);

        if (!symlink($logFile, $logFileLink)) {
            undef($log_fh);
            $self->{errorMessage} = "could not create log file link -- $!";
            return 0;
        }
    }

    # setting handle
    $self->{ handle   } = $log_fh;
    $self->{ $logFile } = 1;

    return 1;

} # end of private method "_open"

sub _opened {

    # private method to test the open status of a log file
    #
    # parameters: $self    (input) - referent to an logging object
    #             $logFile (input) - the log file

    # input as hidden local variable
    my $self    = shift;
    my $logFile = shift;

    # testing open status
    if (defined $logFile) {
        if (exists $self->{$logFile}) {
            return 1;
        }
        else {
            return 0;
        }
    }
    else {
        if (exists $self->{handle}) {
            return 1;
        }
        else {
            return 0;
        }
    }

} # end of private method "_opened"

sub _close {

    # private method to close a log file
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self = shift;

    # getting current log file
    my $logFile = $self->getLogFile();

    # deleting filehandle if open
    if ($self->_opened($logFile)) {

        # closing filehandle
        $self->{handle} = undef;

        # deleting filehandle
        delete $self->{ handle   };
        delete $self->{ $logFile } if (defined $logFile);

        return 1;

    }
    else {

        # error: log file was not open
        $self->{errorMessage} = "log file already closed";

        return 0;
    }

} # end of private method "_close"

sub _rotate {

    # private method to rotate a log file
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self = shift;

    # hidden local variables
    my $timestamp = time;   # the new timestamp
    my $oldTimestamp;       # the old timestamp
    my $doRotate  = 0;      # rotation flag
    my $scheme;             # the rotation scheme
    my %processScheme;      # the action table to process the scheme given

    # performing rotation due to scheme
    $scheme = $self->getRotationScheme();
    if (!defined $scheme) {
        $self->{errorMessage} = "no rotation scheme defined";
        return 0;
    }

    # setting up the action table
    %processScheme = (
        daily   =>  sub { # rotation based on a daily basis

                        $oldTimestamp = $self->_getTimestamp();
                        my $newDay    = time2str("%Y-%m-%d", $timestamp);

                        if (defined $oldTimestamp) {
                            my $oldDay = time2str("%Y-%m-%d", $oldTimestamp);
                            if ($newDay ne $oldDay) {
                                $doRotate  = 1;
                            }
                        }

                    },
        period  =>  sub { # rotation based on period
                        $oldTimestamp = $self->_getTimestamp();
                        my $period    = $self->getRotationPeriod();

                        if (defined $oldTimestamp and defined $period) {
                            if (abs($timestamp-$oldTimestamp) >= $period) {
                                $doRotate = 1;
                            }
                        }

                    },
        size    =>  sub { # rotation based on size
                        my $logFile = $self->getLogFile();

                        if (defined $logFile) {
                            my $fileSize = -s $logFile;
                            if ($fileSize >= $self->getRotationSize()) {
                                $doRotate = 1;
                            }
                        }

                    },
    );

    # processing scheme
    if (exists $processScheme{$scheme}) {
        $processScheme{$scheme}->();
    }
    else {
        # default: no rotation at all (assignment not required, but the
        # hell know's ...)
        $doRotate = 0;
    }

    # performing rotation
    if ($doRotate) {

        # closing log file
        if ($self->_close()) {

            # setting new log file
            $self->_setLogFile($timestamp);

            # opening new log file
            return $self->_open($self->getLogFile());

        }
        else {
            
            # close failed
            return 0;

        }

    }
    else {

        # no rotation required
        return 1;

    }

} # end of private method "_rotate"

sub _setLogFile {

    # private method to set the log file
    #
    # parameters: $self (input)      - referent to a logging object
    #             $timestamp (input) - current timestamp in seconds 

    # input as hidden local variable
    my $self      = shift;
    my $timestamp = @_ ? shift : undef;

    # hidden local variables
    my $scheme;             # the rotation scheme
    my $daystamp;           # the timestamp converted to daystamp     
    my $oldTimestamp;       # the old timestamp
    my $oldDaystamp;        # the old timestamp converted to daystamp     
    my $logFile;            # the log file
    my $oldLogFile;         # the previous log file
    my $counter;            # the log file counter
    my $name;               # log file name
    my $path;               # log file path
    my $suffix;             # log file suffix

    # getting old log file
    $oldLogFile = $self->getLogFile();

    # no timestamp, no log file
    if (!defined $timestamp) {
        $self->{logfile} = undef;
        return $oldLogFile;
    }

    # getting rotation scheme
    $scheme = $self->getRotationScheme();

    if (defined $scheme and !$ROTATION_SCHEME{$scheme}) {
        # no rotation, setting log file to log file base
        $self->{logfile} = $self->{_fileBase};
        return $oldLogFile;
    }

    # setting timestamp and log file
    $daystamp     = time2str("%Y-%m-%d", $timestamp);
    $oldTimestamp = $self->_setTimestamp($timestamp);

    if (defined $oldTimestamp) {
        $oldDaystamp = time2str("%Y-%m-%d", $oldTimestamp);
    }
    else {
        $oldDaystamp = $daystamp;
    }

    $logFile = $self->{_fileBase}.q{.}.$daystamp;

    # getting new log file counter
    if (defined $oldLogFile) {

        if ($daystamp eq $oldDaystamp) {
            # still the same day
            ($name, $path, $suffix) = fileparse($oldLogFile, '\.[0-9]$');
            ($counter = $suffix) =~ s/\.//g;;
        }
        else {
            # we have a roll over
            $counter = -1;
        }

    }
    else {

        ($name, $path, $suffix) = fileparse($logFile, '');

        my @filelist = ();
        find(sub {/^$name\.[0-9]$/ && push(@filelist, $_)}, $path);

        if (@filelist) {
            
            # we have some log files already
            $oldLogFile = pop(@filelist);
            ($name, $path, $suffix) = fileparse($oldLogFile, '\.[0-9]$');
            ($counter = $suffix) =~ s/\.//g;;

        }
        else {
            # no log files around, init ...
            $counter = -1;
        }
    }

    if ($counter < 9) { 
        $counter++;
    }
    else {
        $counter = 0;
    }

    # setting log file
    $self->{logfile} = $logFile.".".$counter;

    return $oldLogFile;

} # end of private method "_setLogFile"

sub _setRotationPeriod {

    # private method to set the rotation period
    #
    # parameters: $self   (input) - referent to a logging object
    #             $period (input) - the rotation period

    # input as hidden local variables
    my $self   = shift;
    my $period = shift;

    # getting old rotation period
    my $oldPeriod = $self->getRotationPeriod();

    # setting new rotation period
    $self->{period} = $period;

    # returning old rotation period
    return $oldPeriod;

} # end of private method "_setRotationPeriod"

sub _setRotationSize {

    # private method to set the rotation size
    #
    # parameters: $self (input) - referent to a logging object
    #             $size (input) - the rotation size

    # input as hidden local variables
    my $self = shift;
    my $size = shift;

    # getting old rotation size
    my $oldSize = $self->getRotationSize();

    # setting new rotation size
    $self->{size} = $size;

    # returning old rotation size
    return $oldSize;

} # end of private method "_setRotationSize"

sub _setRotationScheme {

    # private method to set the rotation scheme
    #
    # parameters: $self   (input) - referent to a logging object
    #             $scheme (input) - the rotation scheme:
    #                               $scheme = none   - no rotation at all;
    #                                                  this is the default;
    #                                       = daily  - rotation on a daily
    #                                                  basis;
    #                                       = period - rotation based on given
    #                                                  period;
    #                                       = size   - rotation based on given
    #                                                  size.

    # input as hidden local variables
    my $self   = shift;
    my $scheme = shift;

    # getting old rotation scheme
    my $oldScheme = $self->getRotationScheme();

    # setting new rotation scheme
    $self->{scheme} = $scheme;

    # returning old rotation scheme
    return $oldScheme;

} # end of private method "_setRotationScheme"

sub _setTimestamp {

    # private method to set the timestamp
    #
    # parameters: $self      (input) - referent to a logging object
    #             $timestamp (input) - the timestamp

    # input as hidden local variables
    my $self      = shift;
    my $timestamp = shift;

    # getting old timestamp
    my $oldTimestamp = $self->_getTimestamp();

    # setting new timestamp
    $self->{_timestamp} = $timestamp;

    # returning old rotation period
    return $oldTimestamp;

} # end of private method "_setTimestamp"

sub _getTimestamp {

    # private method to get the current timestamp
    #
    # parameters: $self (input) - referent to a logging object

    # input as hidden local variable
    my $self = shift;

    # getting timestamp
    if (exists $self->{_timestamp}) {
        return $self->{_timestamp};
    } else {
        return;
    }

} # end of private method "_getTimestamp"

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

Hardware::UPS::Perl::Logging - package of methods for logging.

=head1 SYNOPSIS

    use Hardware::UPS::Perl::Logging;

    $logger = Hardware::UPS::Perl::Logging->new();

    $logger = Hardware::UPS::Perl::Logging->new(
        File    =>  "/var/log/ups.log"
        Period  =>  84600,
    );

    $logger = Hardware::UPS::Perl::Logging->new(
        File    =>  "/var/log/ups.log"
        Size    =>  5,
    );

    $logger = Hardware::UPS::Perl::Logging->new(
        File    =>  "/var/log/ups.log"
        Scheme  =>  "daily",
    );

    $logger->debug("this is a debug message");
    $logger->info("this is a information message");
    $logger->error("this is an error message");
    $logger->fatal("this is a fatal error message");
    $logger->print("this is a message");

    $logger->write(
        Format    => $formatString,
        Arguments => \%formatArguments,
    );

    $logger->syslog(
        level   => "LOG_DEBUG",
        message => "this is a debug message for syslog"
    );

    $logger->sendmail(
        MailTo  => root,
        Subject => "fatal error",
        message => "there was a fatal error",
    );

    $logger->rotate();

    undef $logger;                        # closes log file

=head1 DESCRIPTION

B<Hardware::UPS::Perl::Logging> provides methods to print debug, info,
non-fatal and fatal error messages to log files, to syslog or sending them per
mail.

The log files can be rotated automatically using an ALARM signal handler due
to a certain scheme saving up to 10 files on a FIFO basis. The naming
convention for such log files is F<file.YYYY-MM-DD.x> with F<x> ranging from 0
to 9. The current log file is always available by the symbolic link F<file>.
In case of a restart, the counter F<x> is incremented as well.

The printing operation to log files blocks the rotation to avoid loss of
information. If no log file is specified, all messages are printed on
F<STDERR>.

=head1 LIST OF METHODS

=head2 new

=over 4

=item B<Name:>

new - creates a new logging object

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Logging->new();

	$logger = Hardware::UPS::Perl::Logging->new({
	    File    => $file,
	    Period  => $period,
    });
	$logger = Hardware::UPS::Perl::Logging->new({
	    File    => $file,
	    Scheme  => "period",
    });

	$logger = Hardware::UPS::Perl::Logging->new({
	    File    => $file,
	    Size    => $size,
    });
	$logger = Hardware::UPS::Perl::Logging->new({
	    File    => $file,
	    Scheme  => "size",
    });

	$logger = Hardware::UPS::Perl::Logging->new({
	    File    => $file,
	    Scheme  => "daily",
    });

=item B<Description:>

B<new> initializes a logging object $logger by opening the log file named
F<$file.YYYY-MM-DD.x>, where F<x> denotes the current log file index in the
rotation sequence ranging form 0 to 9, and creates the symbolic link named
F<$file> to it. If the log file does not exist, it will be created. If it is
already available, the file will be truncated. The log file will be
automatically rotated due to one of the schemes described below.

B<new> expects the options as an anonymous hash.

=item B<Arguments:>

=over 4

=item C<< File      => $file >>

optional; the basename of the log file; if omitted, all output will be sent to
F<STDERR>.

=item C<< MailTo    => $mailTo >>

optional; the mail address a message is sent to; if not specified, the default
mail address F<UPSMAILTO> supplied by package
B<Hardware::UPS::Perl::Constants> will be used.

=item C<< Period    => $period >>

optional; the rotation period in seconds; if not specified and the rotation
scheme F<period> is selected, a default rotation period of 86400 seconds, i.e.
1 day will be used.

=item C<< Scheme    => $scheme >>

optional; the rotation scheme; overrides the scheme set by the B<Period>
or B<Size> option; the following schemes are available:

=over 4

=item C<< none >>

The log file will not be rotated at all except at restart.

=item C<< daily >>

The log file will be rotated on a daily basis.

=item C<< period >>

The log file will be rotated after a certain period of time.

=item C<< size >>

The log file will be rotated after it has reached a certain size in megabytes.

=back

=item C<< Size      => $size >>

optional; the rotation size in megabytes; if not supplied and the size based
rotation scheme is choosen, a default rotation size of 1 megabyte will be
used.

=back

=item B<See Also:>

L<"debug">,
L<"error">,
L<"fatal">,
L<"getHandle">,
L<"getLogFile">,
L<"getMailTo">,
L<"getRotationPeriod">,
L<"getRotationScheme">,
L<"getRotationSize">,
L<"info">,
L<"print">,
L<"rotate">.
L<"sendmail">,
L<"setMailTo">,
L<"syslog">,
L<"write">

=back

=head2 getErrorMessage

=over 4

=item B<Name:>

getErrorMessage - gets the internal error message

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Logging->new();

	unless(defined $logger) {
	    print STDERR $logger->getErrorMessage(), "\n";
	    exit 0;
	}

=item B<Description:>

B<getErrorMessage> returns the internal error message, if something went
wrong.

=back

=head2 getHandle

=over 4

=item B<Name:>

getHandle - gets the filehandle of the current log file

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new(
	    File    => $file.
	);

	$fh = $logger->getHandle();

=item B<Description:>

B<getHandle> returns the filehandle of the current log file used for logging.

=item B<See Also:>

L<"new">,
L<"getLogFile">

=back

=head2 getLogFile

=over 4

=item B<Name:>

getLogFile - gets the current log file

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new(
	    File    => "$HOME/tmp.log",
	);

	$file = $logger->getLogFile();

=item B<Description:>

B<getLogFile> returns the current log file used for logging.

=item B<See Also:>

L<"new">,
L<"getHandle">,
L<"getRotationPeriod">,
L<"getRotationScheme">,
L<"getRotationSize">,
L<"rotate">

=back

=head2 getRotationPeriod

=over 4

=item B<Name:>

getRotationPeriod - gets the current rotation period

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new(
	    File    => "$HOME/tmp.log",
	);

	$period = $logger->getRotationPeriod();

=item B<Description:>

B<getRotationPeriod> returns the rotation period in minutes.

=item B<See Also:>

L<"new">,
L<"getHandle">,
L<"getLogFile">,
L<"getRotationScheme">,
L<"getRotationSize">,
L<"rotate">

=back

=head2 getRotationScheme

=over 4

=item B<Name:>

getRotationScheme - gets the current rotation scheme

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new(
	    File    => "$HOME/tmp.log",
	);

	$scheme = $logger->getRotationScheme();

=item B<Description:>

B<getRotationScheme> returns the rotation scheme.

=item B<See Also:>

L<"new">,
L<"getHandle">,
L<"getLogFile">,
L<"getMailTo">,
L<"getRotationPeriod">,
L<"getRotationSize">,
L<"rotate">

=back

=head2 getRotationSize

=over 4

=item B<Name:>

getRotationSize - gets the current rotation scheme

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new(
	    File    => "$HOME/tmp.log",
	    Scheme  => "size",
	);

	$scheme = $logger->getRotationSize();

=item B<Description:>

B<getRotationSize> returns the rotation size in megabytes.

=item B<See Also:>

L<"new">,
L<"getHandle">,
L<"getLogFile">,
L<"getMailTo">,
L<"getRotationPeriod">,
L<"getRotationScheme">,
L<"rotate">

=back

=head2 rotate

=over 4

=item B<Name:>

rotate - forces rotation of log file

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new(
	    File    => "$HOME/tmp.log",
	);

	$logger->rotate();

=item B<Description:>

B<rotate> forces the rotation of the log file.

=item B<See Also:>

L<"new">,
L<"getHandle">,
L<"getLogFile">,
L<"getRotationPeriod">,
L<"getRotationScheme">,
L<"getRotationSize">

=back

=head2 debug

=over 4

=item B<Name:>

debug - prints a debug message to log file

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new(
	    File    => "$HOME/tmp.log",
	);

	$logger->debug("This is a debug message");

=item B<Description:>

B<debug> prints a debug message to the current log file.

=item B<Arguments:>

=over 4

=item C<< $debugMessage >>

string; the debug message.

=back

=item B<See Also:>

L<"new">,
L<"error">,
L<"getHandle">,
L<"getLogFile">,
L<"info">,
L<"fatal">,
L<"print">,
L<"syslog">,
L<"write">

=back

=head2 info

=over 4

=item B<Name:>

info - prints an info message to log file

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new(
	    File    => "$HOME/tmp.log",
	);

	$logger->info("This is an info message");

=item B<Description:>

B<info> prints an info message to the current log file.

=item B<Arguments:>

=over 4

=item C<< $infoMessage >>

string; the info message.

=back

=item B<See Also:>

L<"new">,
L<"debug">,
L<"error">,
L<"getHandle">,
L<"getLogFile">,
L<"fatal">,
L<"print">,
L<"syslog">,
L<"write">

=back

=head2 error

=over 4

=item B<Name:>

error - prints a non-fatal error message to log file

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new(
	    File    => "$HOME/tmp.log",
	);

	$logger->error("This is an error message");

=item B<Description:>

B<error> prints a non-fatal error message to the current log file.

=item B<Arguments:>

=over 4

=item C<< $errorMessage >>

string; the error message.

=back

=item B<See Also:>

L<"new">,
L<"debug">,
L<"getHandle">,
L<"getLogFile">,
L<"info">,
L<"fatal">,
L<"print">,
L<"syslog">,
L<"write">

=back

=head2 fatal

=over 4

=item B<Name:>

fatal - prints a fatal error message to log file and dies

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new(
	    File    => "$HOME/tmp.log",
	);

	$logger->fatal("This is a fatal error message");

=item B<Description:>

B<fatal> prints a fatal error message to the current log file and to STDERR
using B<Carp::croak> thus causing the script to die.

=item B<Arguments:>

=over 4

=item C<< $fatalMessage >>

string; the fatal error message.

=back

=item B<See Also:>

L<"new">,
L<"debug">,
L<"error">,
L<"getHandle">,
L<"getLogFile">,
L<"info">,
L<"fatal">,
L<"print">,
L<"syslog">,
L<"write">

=back

=head2 print

=over 4

=item B<Name:>

print - prints a general log message to the log file

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new(
	    File    => "$HOME/tmp.log",
	);

	$logger->print("This is a normal log message");

=item B<Description:>

B<prints> prints a normal log message to the current log file. The message is
prepended by the current date in the format F<%b %d %T>, e.g. F<Feb 03
15:24:52>, and the script name separated by colons. While printing to the log
file, the rotation is blocked.

=item B<Arguments:>

=over 4

=item C<< $message >>

string; the message.

=back

=item B<See Also:>

L<"new">,
L<"debug">,
L<"error">,
L<"getHandle">,
L<"getLogFile">,
L<"info">,
L<"fatal">,
L<"syslog">,
L<"write">

=back

=head2 write

=over 4

=item B<Name:>

write - writes a formatted log message to the log file

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new({
	    File    => "$HOME/tmp.log",
    });

	$logger->write({
        Format      => $formatString,
        Arguments   => \%formatArguments,
    });

=item B<Description:>

B<write> prints a formatted log message to the current log file. The message is
prepended by the current date in the format F<%b %d %T>, e.g. F<Feb 03
15:24:52>, and the script name separated by colons. While printing to the log
file, the rotation is blocked.

B<write> expects the options as an anonymous hash.

=item B<Arguments:>

=over 4

=item C<< Format    => $formatString >>

required; the string declaring a format.

=item C<< Arguments => \%arguments >>

required; an hash reference holding the arguments required by the format and
their values.

=back

=item B<See Also:>

L<"new">,
L<"debug">,
L<"error">,
L<"fatal">,
L<"getHandle">,
L<"getLogFile">,
L<"info">,
L<"print">,
L<"syslog">

=back

=head2 syslog

=over 4

=item B<Name:>

syslog - prints a message to syslog

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new();

	$logger->syslog({
	    level   => "LOG_DEBUG",
	    message => "This is a LOG_DEBUG level message"
    });

=item B<Description:>

B<syslog> prints a message to syslog using Perl5 extension package
B<Sys:Syslog> at the facility "UPS".

B<syslog> expects the options as an anonymous hash.

=item B<Arguments:>

=over 4

=item C<< level     => $level >>

string; the priority level; if not specified, LOG_DEBUG is assumed.

=item C<< message   => $message >>

string; the message.

=back

=item B<See Also:>

L<"new">,
L<"debug">,
L<"error">,
L<"getHandle">,
L<"getLogFile">,
L<"info">,
L<"fatal">,
L<"print">,
L<"syslog">,
L<"write">

=back

=head2 setMailTo

=over 4

=item B<Name:>

setMailTo - gets the current mail address

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new();

	$oldMailto = $logger->setMailTo($mailto);

=item B<Description:>

B<setMailto> sets the mail address being used to send mail to. It returns the
previously used mail address.

=item B<Arguments:>

=over 4

=item C<< $mailto >>

string; a valid mail address.

=back

=item B<See Also:>

L<"new">,
L<"getMailTo">,
L<"sendmail">

=back

=head2 getMailTo

=over 4

=item B<Name:>

getMailTo - gets the current mail address

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new();

	$mailto = $logger->getMailTo();

=item B<Description:>

B<getMailto> returns the current mail address used to send mails to.

=item B<See Also:>

L<"new">,
L<"setMailTo">,
L<"sendmail">

=back

=head2 sendmail

=over 4

=item B<Name:>

sendmail - prints a message to syslog

=item B<Synopsis:>

	$logger = Hardware::UPS::Perl::Net->new();

	$logger->sendmail({
	    MailTo  => $mailto,
	    Subject => "This is the mail message",
	    Message => "This is the mail subject",
    });

=item B<Description:>

B<sendmail> sends a message to the current mail recipient using Perl5
extension package B<Mail:Send>. The subject is prepended by the name
of the calling script and the hostname, the script is running on.

B<sendmail> expects the options as an anonymous hash.

=item B<Arguments:>

=over 4

=item C<< MailTo    => $mailto >>

string; the mail address; if not specified, F<UPSMAILTO> provided by
B<Hardware::UPS::Perl::Constants> is used.

=item C<< Message   => $message >>

string; the mail message; if not specified, the string F<event occured at
$date> is used, where F<$date> denotes the current date.

=item C<< Subject   => $subject >>

string; the mail subject; the mail subject is prepended by the string
F<UPSSCRIPT at UPSHOSTNAME: >, both as provided by package
B<Hardware::UPS::Perl::Constants>; if the subject is not specified, the colon
and the space at the end are omitted.

=back

=item B<See Also:>

L<"new">,
L<"getMailTo">,
L<"setMailTo">

=back

=head1 SEE ALSO

Carp(3pm),
Date::Format(3pm),
Fcntl(3pm),
File::Basename(3pm),
File::Find(3pm),
FileHandle(3pm),
Mail::Send(3pm),
Sys::Syslog(3pm),
Time::HiRes(3pm),
Hardware::UPS::Perl::Connection(3pm),
Hardware::UPS::Perl::Connection::Net(3pm),
Hardware::UPS::Perl::Connection::Serial(3pm),
Hardware::UPS::Perl::Constants(3pm),
Hardware::UPS::Perl::Driver(3pm),
Hardware::UPS::Perl::Driver::Megatec(3pm),
Hardware::UPS::Perl::General(3pm),
Hardware::UPS::Perl::PID(3pm),
Hardware::UPS::Perl::Utils(3pm) 

=head1 NOTES

B<Hardware::UPS::Perl::Logging> was inspired by many Perl modules dealing with
logging. Unfortunately, either those modules are not included in a standard
B<SuSE 10.1> Linux distribution, or they did not quite fit to my needs.

B<Hardware::UPS::Perl::Logging> was developed using B<perl 5.8.8> on a B<SuSE
10.1> Linux distribution.

=head1 BUGS

There are plenty of them for sure. Maybe the embedded pod documentation has to
be revised a little bit.

Suggestions to improve B<Hardware::UPS::Perl::Logging> are welcome, though due
to the lack of time it might take a while to incorporate them.

=head1 AUTHOR

Copyright (c) 2007 by Christian Reile, E<lt>Christian.Reile@t-online.deE<gt>.
All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself. For further licensing
details, please see the file COPYING in the distribution.

=cut
