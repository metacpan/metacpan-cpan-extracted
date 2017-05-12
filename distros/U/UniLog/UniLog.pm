package UniLog;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS @EXPORT_FAIL);

#$^W++;

require Exporter;

@ISA = qw(Exporter);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
);

%EXPORT_TAGS = ('levels'     => [qw(LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR
			            LOG_WARNING LOG_NOTICE LOG_INFO LOG_DEBUG  )],
		'options'    => [qw(LOG_CONS LOG_NDELAY LOG_PERROR LOG_PID)],
		'facilities' => [qw(LOG_AUTH LOG_CRON LOG_DAEMON
				    LOG_KERN LOG_LPR LOG_MAIL LOG_NEWS
				    LOG_SECURITY LOG_SYSLOG LOG_USER LOG_UUCP
				    LOG_LOCAL0 LOG_LOCAL1 LOG_LOCAL2 LOG_LOCAL3
				    LOG_LOCAL4 LOG_LOCAL5 LOG_LOCAL6 LOG_LOCAL7)],
		'functions'  => [qw(SafeStr)],
		'syslog'     => [qw(syslog)],
		'nosyslog'   => [qw(nosyslog)],
		);

foreach (keys(%EXPORT_TAGS))
        { push(@{$EXPORT_TAGS{'all'}}, @{$EXPORT_TAGS{$_}}); };

$EXPORT_TAGS{'all'}
	and @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT_FAIL = qw(syslog nosyslog);	# hook to enable/disable syslog

$VERSION = '0.14';

use Carp qw(carp croak cluck confess);
use POSIX;
use IO::File;
use File::Path;
use File::Basename;

sub LOG_CONS()   { return 2; };
sub LOG_NDELAY() { return 8; };
sub LOG_PID()    { return 1; };
my %LogOptions = (LOG_CONS()   => LOG_CONS(),
                  LOG_NDELAY() => LOG_NDELAY(),
                  LOG_PID()    => LOG_PID(),
                 );
my $CalcOpt = sub
	{
	my $Result = 0;
	foreach (keys(%LogOptions))
		{
		if ($_[0] & $_)
			{ $Result = $Result | $LogOptions{$_}; };
		};
	return $Result;
	};

#
# Define log levels
my @LogLevels     = (0, 1, 2, 3, 4, 5, 6, 7);
#
sub LOG_EMERG()   { return 0; };
sub LOG_ALERT()   { return 1; };
sub LOG_CRIT()    { return 2; };
sub LOG_ERR()     { return 3; };
sub LOG_WARNING() { return 4; };
sub LOG_NOTICE()  { return 5; };
sub LOG_INFO()    { return 6; };
sub LOG_DEBUG()   { return 7; };

#
# Define log facilities
my %LogFacilities = ('LOG_AUTH'     =>  1,
                     'LOG_AUTHPRIV' =>  2,
                     'LOG_CRON'     =>  3,
                     'LOG_DAEMON'   =>  4,
                     'LOG_FTP'      =>  5,
                     'LOG_KERN'     =>  6,
                     'LOG_LPR'      =>  7,
                     'LOG_MAIL'     =>  8,
                     'LOG_NEWS'     =>  9,
                     'LOG_SYSLOG'   => 10,
                     'LOG_USER'     => 11,
                     'LOG_UUCP'     => 12,
                     'LOG_LOCAL0'   => 13,
                     'LOG_LOCAL1'   => 14,
                     'LOG_LOCAL2'   => 15,
                     'LOG_LOCAL3'   => 16,
                     'LOG_LOCAL4'   => 17,
                     'LOG_LOCAL5'   => 18,
                     'LOG_LOCAL6'   => 19,
                     'LOG_LOCAL7'   => 20,
                    );
#
sub LOG_AUTH()     { return 'LOG_AUTH'; };
#sub LOG_AUTHPRIV() { return 'LOG_AUTHPRIV'; };
sub LOG_CRON()     { return 'LOG_CRON'; };
sub LOG_DAEMON()   { return 'LOG_DAEMON'; };
#sub LOG_FTP()      { return 'LOG_FTP'; };
sub LOG_KERN()     { return 'LOG_KERN'; };
sub LOG_LPR()      { return 'LOG_LPR'; };
sub LOG_MAIL()     { return 'LOG_MAIL'; };
sub LOG_NEWS()     { return 'LOG_NEWS'; };
sub LOG_SYSLOG()   { return 'LOG_SYSLOG'; };
sub LOG_USER()     { return 'LOG_USER'; };
sub LOG_UUCP()     { return 'LOG_UUCP'; };
sub LOG_LOCAL0()   { return 'LOG_LOCAL0'; };
sub LOG_LOCAL1()   { return 'LOG_LOCAL1'; };
sub LOG_LOCAL2()   { return 'LOG_LOCAL2'; };
sub LOG_LOCAL3()   { return 'LOG_LOCAL3'; };
sub LOG_LOCAL4()   { return 'LOG_LOCAL4'; };
sub LOG_LOCAL5()   { return 'LOG_LOCAL5'; };
sub LOG_LOCAL6()   { return 'LOG_LOCAL6'; };
sub LOG_LOCAL7()   { return 'LOG_LOCAL7'; };

# Define syslog functions
my $OpenLog  = undef;
my $CloseLog = undef;
my $PutMsg   = undef;

my $SyslogEnabled = 1;

my $InitSyslog = sub
	{
	if ( $^O =~ m/win32/i )
		{
		if (!Win32::IsWinNT())
			{
			#$OpenLog  = sub { return 1; };
			#$CloseLog = sub { return 1; };
			#$PutMsg   = sub { return 1; };
			$SyslogEnabled = 0;
			carp "Win32::EventLog is not supporting Win32 systems other WinNT. Syslog functionality disabled\n";
			return;
			};
		
		eval   'use Win32::EventLog;
		        $OpenLog  = sub
		        	{
		        	my ($Ident, $Options, $Facility) = @_;
				if ($Options & LOG_PID())
					{ $Ident .= "[$$]" };
				return Win32::EventLog->new($Ident, $ENV{ComputerName});
				};
		        $CloseLog = sub
		        	{
		        	$_[0]->{Handler}->Close();
		        	};
		        $PutMsg = sub
		        	{ $_[0]->{Handler}->Report({EventType => $_[1],
		        				    Strings   => $_[2],
		        				    Category  => $_[0]->{"Facility"},
		        				    EventID   => 0,
		        				    Data      => "",
		        				   });
				};
			$LogLevels[LOG_EMERG()]   = EVENTLOG_ERROR_TYPE;
			$LogLevels[LOG_ALERT()]   = EVENTLOG_ERROR_TYPE;
			$LogLevels[LOG_CRIT()]    = EVENTLOG_ERROR_TYPE;
			$LogLevels[LOG_ERR()]     = EVENTLOG_ERROR_TYPE;
			$LogLevels[LOG_WARNING()] = EVENTLOG_WARNING_TYPE;
			$LogLevels[LOG_NOTICE()]  = EVENTLOG_INFORMATION_TYPE;
			$LogLevels[LOG_INFO()]    = EVENTLOG_INFORMATION_TYPE;
			$LogLevels[LOG_DEBUG()]   = EVENTLOG_INFORMATION_TYPE;
		        ';
		}
	else
		{
		eval   'use Unix::Syslog;
		        $OpenLog  = sub {
		        		my ($Ident, $Options, $Facility) = @_;
					Unix::Syslog::openlog($Ident, $Options, $Facility);
	                		return 1;
	                		};
	                $CloseLog = sub { Unix::Syslog::closelog; };
	                $PutMsg   = sub { Unix::Syslog::syslog($_[1], "%s", $_[2]); };
			# Set real log levels
			$LogLevels[LOG_EMERG()]   = Unix::Syslog::LOG_EMERG;
			$LogLevels[LOG_ALERT()]   = Unix::Syslog::LOG_ALERT;
			$LogLevels[LOG_CRIT()]    = Unix::Syslog::LOG_CRIT;
			$LogLevels[LOG_ERR()]     = Unix::Syslog::LOG_ERR;
			$LogLevels[LOG_WARNING()] = Unix::Syslog::LOG_WARNING;
			$LogLevels[LOG_NOTICE()]  = Unix::Syslog::LOG_NOTICE;
			$LogLevels[LOG_INFO()]    = Unix::Syslog::LOG_INFO;
			$LogLevels[LOG_DEBUG()]   = Unix::Syslog::LOG_DEBUG;
			#
			# Set log options
			$LogOptions{LOG_CONS()}   = Unix::Syslog::LOG_CONS;
			$LogOptions{LOG_NDELAY()} = Unix::Syslog::LOG_NDELAY;
			$LogOptions{LOG_PID()}    = Unix::Syslog::LOG_PID;
			#
			# Set log facilities
			$LogFacilities{LOG_AUTH()}     = Unix::Syslog::LOG_AUTH;
			#$LogFacilities{LOG_AUTHPRIV()} = Unix::Syslog::LOG_AUTHPRIV;
			$LogFacilities{LOG_CRON()}     = Unix::Syslog::LOG_CRON;
			$LogFacilities{LOG_DAEMON()}   = Unix::Syslog::LOG_DAEMON;
			#$LogFacilities{LOG_FTP()}      = Unix::Syslog::LOG_FTP;
			$LogFacilities{LOG_KERN()}     = Unix::Syslog::LOG_KERN;
			$LogFacilities{LOG_LPR()}      = Unix::Syslog::LOG_LPR;
			$LogFacilities{LOG_MAIL()}     = Unix::Syslog::LOG_MAIL;
			$LogFacilities{LOG_NEWS()}     = Unix::Syslog::LOG_NEWS;
			$LogFacilities{LOG_SYSLOG()}   = Unix::Syslog::LOG_SYSLOG;
			$LogFacilities{LOG_USER()}     = Unix::Syslog::LOG_USER;
			$LogFacilities{LOG_UUCP()}     = Unix::Syslog::LOG_UUCP;
			$LogFacilities{LOG_LOCAL0()}   = Unix::Syslog::LOG_LOCAL0;
			$LogFacilities{LOG_LOCAL1()}   = Unix::Syslog::LOG_LOCAL1;
			$LogFacilities{LOG_LOCAL2()}   = Unix::Syslog::LOG_LOCAL2;
			$LogFacilities{LOG_LOCAL3()}   = Unix::Syslog::LOG_LOCAL2;
			$LogFacilities{LOG_LOCAL4()}   = Unix::Syslog::LOG_LOCAL4;
			$LogFacilities{LOG_LOCAL5()}   = Unix::Syslog::LOG_LOCAL5;
			$LogFacilities{LOG_LOCAL6()}   = Unix::Syslog::LOG_LOCAL6;
			$LogFacilities{LOG_LOCAL7()}   = Unix::Syslog::LOG_LOCAL7;
	                ';
		};
	
	# These linea are necessary!
	foreach (@LogLevels)           { my $tmpVar = $_; };
	foreach (keys(%LogOptions))    { my $tmpVar = $_; };
	foreach (keys(%LogFacilities)) { my $tmpVar = $_; };
	
	if ($@) { croak $@; };
	if ($^W) { carp "Syslog functionality enabled\n"; };
	my $tmpVar = $OpenLog.$CloseLog.$PutMsg; # This string is necessary.
	return 1;
	};

sub export_fail
	{
	shift;
	if ($_[0] eq 'nosyslog')
		{
		shift;
		#$InitSyslog    = undef;
		$SyslogEnabled = 0;
		if ($^W) { carp "Syslog functionality disabled\n"; };
		}
	elsif ($_[0] eq 'syslog')
		{
		shift;
		if ($InitSyslog && !$OpenLog)
			{ &{$InitSyslog}(); };
		}
	return @_;
	};

# Preloaded methods go here.

my $FileReOpen = sub
	{
	my ($self) = @_;

	my @tm = POSIX::localtime(POSIX::time());
	my $NewName = POSIX::strftime($self->{'LogFileNameTemplate'}, @tm)
		or confess "Can not create log file name from template \"".SafeStr($self->{'LogFileNameTemplate'})."\"\n";

	if ($self->{'LogFileHandler'} &&
	    defined($self->{'LogFileNameCurrent'}) &&
	    ($NewName eq $self->{'LogFileNameCurrent'}))
		{ return $self->{'LogFileNameCurrent'}; };

	$self->{'LogFileNameCurrent'} = $NewName;
	
	if ($self->{'LogFileHandler'})
		{ $self->{'LogFileHandler'}->close(); };

	if (!length($NewName))
		{ return $NewName; };

	File::Path::mkpath(File::Basename::dirname($NewName), 0, $self->{'DirPerms'});

	$self->{'LogFileHandler'} = IO::File->new($NewName, ($self->{'Truncate'} ? '>' : '>>'))
		or return;
	if (chmod($self->{'FilePerms'}, $NewName) < 1)
		{ carp sprintf("Can not change file \"%s\" permissions to '%04o'\n", SafeStr($NewName), $self->{'FilePerms'}); };

	autoflush {$self->{'LogFileHandler'}} 1;

	return $self->{'LogFileHandler'};
	};

sub new($%)
	{
	my ($class, %LogParam) = @_;

	if ($SyslogEnabled && !$OpenLog)
		{ &{$InitSyslog}(); };

	my %DefParam = ('Ident'     => $0,
	                'Level'     => 6,
	                'StdErr'    => 0,
	                'SysLog'    => 1,
	                'DirPerms'  => 0750,
	                'FilePerms' => 0640,
	                'Truncate'  => 0,
	                'Options'   => LOG_PID() | LOG_CONS(),
	                'Facility'  => LOG_USER(),
	                'SafeStr'   => 1,
	                );

	foreach (keys(%DefParam))
		{
		if (!defined($LogParam{$_}))
			{ $LogParam{$_} = $DefParam{$_}; };
		};

	if (!defined($LogFacilities{$LogParam{'Facility'}}))
		{
                cluck sprintf("Unknown facility \"%s\", use the default facility \"%s\"\n", SafeStr($LogParam{'Facility'}), SafeStr($DefParam{'Facility'}));
		$LogParam{'Facility'} = $DefParam{'Facility'};
		};
	
	my $self = {'Ident'               => SafeStr($LogParam{Ident}),
	            'Level'               => $LogParam{'Level'},
	            'Facility'            => $LogFacilities{$LogParam{'Facility'}},
	            'StdErr'              => $LogParam{'StdErr'},
	            'SysLog'              => ($LogParam{'SysLog'} && $SyslogEnabled),
	            'SafeStr'             => $LogParam{'SafeStr'},
	            'LogFileNameTemplate' => $LogParam{'LogFile'},
	            'Truncate'            => $LogParam{'Truncate'},
	            'DirPerms'            => $LogParam{'DirPerms'},
	            'FilePerms'           => $LogParam{'FilePerms'},
	            'LogFileNameCurrent'  => '',
	            'LogFileHandler'      => undef,
         };

	if ($OpenLog)
		{
		$self->{'Handler'} = &{$OpenLog}($self->{'Ident'}, &{$CalcOpt}($LogParam{'Options'}), $self->{'Facility'});
		if (!$self->{'Handler'})
			{
			$! .= ' '.$@;
			return;
			};
		};

	if (defined($self->{'LogFileNameTemplate'}))
		{
		&{$FileReOpen}($self);
		if (!defined($self->{'LogFileNameTemplate'}))
			{
			$! = sprintf("Can not open file \"%s\": %s", SafeStr($self->{'LogFileNameCurrent'}), $!);
			Close($self);
			return;
			};
		};

	return bless $self => $class;
	};

sub emergency($$@)
	{ return Message(shift, LOG_EMERG(),   @_); };
sub alert($$@)
	{ return Message(shift, LOG_ALERT(),   @_); };
sub critical($$@)
	{ return Message(shift, LOG_CRIT(),    @_); };
sub error($$@)
	{ return Message(shift, LOG_ERR(),     @_); };
sub warning($$@)
	{ return Message(shift, LOG_WARNING(), @_); };
sub notice($$@)
	{ return Message(shift, LOG_NOTICE(),  @_); };
sub info($$@)
	{ return Message(shift, LOG_INFO(),    @_); };
sub debug($$@)
	{ return Message(shift, LOG_DEBUG(),   @_); };

sub Message($$$@)
	{
	my ($self, $Level, $Format, @Args) = @_;

	if    ($Level < 0)
		{
                if ($^W) { cluck "Log level \"$Level\" adjusted from \"$Level\" to \"0\"\n"; };
		$Level = 0;
		}
	elsif ($Level > $#LogLevels)
		{
                if ($^W) { cluck "Log level \"$Level\" adjusted from \"$Level\" to \"$#LogLevels\"\n"; };
		$Level = $#LogLevels;
		};

	if ($Level <= $self->{Level})
		{
		my $Str = $self->{'SafeStr'} ? SafeStr(sprintf($Format, @Args)) : sprintf($Format, @Args);

		if ($self->{'StdErr'})
			{ print STDERR localtime()." $Level $Str\n"; };

		if ($PutMsg)
			{ &{$PutMsg}($self, $LogLevels[$Level], $Str); };

		if (defined($self->{'LogFileNameTemplate'}))
			{
			if (!(&{$FileReOpen}($self)))
				{
				$! = sprintf("Can not open file \"%s\": %s", SafeStr($self->{'LogFileNameCurrent'}), $!);
				return;
				};
			if (!(print {$self->{'LogFileHandler'}} localtime()." $Level $Str\n"))
				{
				$! = sprintf("Can not write to the file \"%s\": %s", SafeStr($self->{'LogFileNameCurrent'}), $!);
				return;
				};
			};
		};
	return 1;
	};

sub Level($$)
	{
	my $Return = $_[0]->{Level};
	if (defined($_[1]))
		{ $_[0]->{Level} = $_[1]; };
	return $Return;
	};

sub SysLog($$)
	{
	my $Return = ($_[0]->{'SysLog'}  && $SyslogEnabled);
	if (defined($_[1]))
		{ $_[0]->{'SysLog'} = ($_[1]  && $SyslogEnabled); };
	return $Return;
	};

sub StdErr($$)
	{
	my $Return = $_[0]->{'StdErr'};
	if (defined($_[1]))
		{ $_[0]->{'StdErr'} = $_[1]; };
	return $Return;
	};

sub LogFile($$)
	{
	if (defined($_[1]))
		{ $_[0]->{'LogFileNameTemplate'} = $_[1]; };
	if (defined($_[2]))
		{ $_[0]->{'FilePerms'} = $_[2]; };
	return $_[0]->{'LogFileNameCurrent'};
	};

sub Permissions($$$)
	{
	my @Return = ($_[0]->{'FilePerms'}, $_[0]->{'DirPerms'});
	if (defined($_[1]))
		{ $_[0]->{'FilePerms'} = $_[1]; };
	if (defined($_[2]))
		{ $_[0]->{'DirPerms'}  = $_[2]; };
	return (wantarray ? @Return : $Return[0]); 
	};

sub Truncate($$)
	{
	my $Return = $_[0]->{'Truncate'};
	if (defined($_[1]))
		{ $_[0]->{'Truncate'} = $_[1]; };
	return $Return;
	};

sub CloseLogFile
	{
	if ($_[0]->{'LogFileHandler'})
		{ $_[0]->{'LogFileHandler'}->close(); };
	$_[0]->{'LogFileHandler'} = undef;
	};

sub Close($)
	{
	if ($CloseLog)
		{ &{$CloseLog}($_[0]); };
	$_[0]->{Handler} = undef;
	#
	if (defined($_[0]->{'LogFileHandler'}))
		{ $_[0]->{'LogFileHandler'}->close(); };
	$_[0]->{'LogFileHandler'} = undef;
	};

sub SafeStr($)
	{
	my $Str = shift
		or return '!UNDEF!';
	$Str =~ s{ ([\x00-\x1f\xff\\]) } { sprintf("\\x%2.2X", ord($1)) }gsex;
	return $Str;
	};

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

UniLog - Perl module for unified logging on Unix and Win32

I<Version 0.14>

=head1 SYNOPSIS

  use UniLog qw(:levels syslog);
  use UniLog qw(:options :facilities); # Not useful on Win32

  $Logger=UniLog->new(Ident    => "MyProgram",
                                  # The log source identification
                      Options  => LOG_PID|LOG_CONS|LOG_NDELAY,
                                  # Logger options, see "man 3 syslog"
                      Facility => LOG_USER,
                                  # Logger facility, see "man 3 syslog"
                      Level    => LOG_INFO,
                                  # The log level                       
                      StdErr   => 1)
                                  # Log messages also to STDERR
       or die "Can not create the logger: $!";

  $Logger->Message(LOG_NOTICE, "Message text here, time: %d", time())
  	or die "Logging error: $!";
           # Send message to the log

  $Logger->Message(LOG_DEBUG, "You should not see this");
           # Will not be logged
  $Logger->Level(LOG_DEBUG);
  $Logger->Message(LOG_DEBUG, "You should see this now");
           # Will be logged

  $Logger->StdErr(0);
           # Stop logging to STDERR
  $Logger->Message(LOG_INFO, "Should not be logged to STDERR");
           # Send message to the log

  $Logger->Close();


=head1 DESCRIPTION

This module provides a unified way to send log messages on Unix and Win32.
Messages are logged using syslog on Unix and using EventLog on Win32.

This module uses L<Unix::Syslog> Perl module on Unix and L<Win32::EventLog> Perl module on Win32.

The idea was to give a programmer a possibility to write a program which will be able to run
on Unix and on Win32 without code adjusting and with the same logging functionality.

I<Notes:>

I<C<Win32::EventLog> does not support any Win32 platform except WinNT.
So, C<UniLog> provides only STDERR and file logging on these platforms.>

I<Logging to remote server is not supported in this release.>

Module was tested on FreeBSD 4.2, Win2000, Win98 and Solaris 7.

=head2 Note about system logging

To utilize the OS logging facilities C<UniLog> is using external modules.
These modules are not available on some platforms.
On these platforms you can use C<UniLog> for STDERR and/or file logging,
you just have to prevent C<UniLog> from attempt to load system logging module.
It can be done by importing 'fake' function I<C<nosyslog>>.
You would typically do it by saying

  perl -MUniLog=nosyslog script.pl

or by including the string C<-MUniLog=nosyslog> in the L<PERL5OPT>
environment variable. Also, the command
  
  use UniLog qw(:levels :options :facilities nosyslog);

can be used inside of perl script.

See also the L<EXPORT> section.

=head1 The UniLog methods

=over 4

=item C<new(%PARAMHASH);>

The C<new> method creates the logger object and returns a handle to it.
This handle is then used to call the methods below.

The I<%PARAMHASH> could contain the following keys:

=over 4

=item C<Ident>

Ident field specifies a string which will be used as message source identifier.
C<syslogd>(8) will print it into every message 
and C<EventLog> will put it to the "Source" message field.

Default is $0, the name of the program being executed. 

=item C<Options>

This is an integer value which is the result of ORed options:
C<LOG_CONS>, C<LOG_NDELAY>, C<LOG_PID>.

See L<Unix::Syslog>, C<syslog>(3) for details.

Default is C<LOG_PID|LOG_CONS>.

This field is ignored on Win32.

=item C<Facility>

This is an integer value which specifies the part of the system the message
should be associated with (e.g. kernel message, mail subsystem).

Could be C<LOG_AUTH>, C<LOG_CRON>, C<LOG_DAEMON>,
C<LOG_KERN>, C<LOG_LPR>, C<LOG_MAIL>, C<LOG_NEWS>, C<LOG_SYSLOG>, 
C<LOG_USER>, C<LOG_UUCP>, C<LOG_LOCAL0>, C<LOG_LOCAL1>, C<LOG_LOCAL2>,
C<LOG_LOCAL3>, C<LOG_LOCAL4>, C<LOG_LOCAL5>, C<LOG_LOCAL6>, C<LOG_LOCAL7>.

See L<Unix::Syslog>, C<syslog>(3) for details.

Default is C<LOG_USER>.

This field is ignored on Win32.

=item C<Level>

This is an integer value which specifies log level.
The message with Level greater than C<Level> will not be logged.
You will be able to change Level using C<Level> method.
See C<Message> method description for available log levels.

Default log level is C<LOG_INFO>.

=item C<SysLog>

If this flag have a 'true' value all messages are logged using
L<Unix::Syslog> or L<Win32::EventLog>, if possible.

You will be able to change this flag using C<SysLog> method.

Default is 1 - log to system log.

=item C<StdErr>

If this flag have a 'true' value all messages are logged to C<STDERR> 
in addition to syslog/EventLog.
You will be able to change this flag using L<StdErr> method.

Default is 0 - do not log to C<STDERR>.

=item C<LogFile>

The name for the log file. If defined, all messages are logged to
this file in addition to syslog/EventLog and C<STDERR>.

The C<LogFile> have to be treated as a template for the file name because it
is processed by C<POSIX::strftime> function before actual file opening.
See L<POSIX::strftime> for details.

Of course, the log file will be automatically changed if necessary.
For example, new log file will be created every hour if C<LogFile> contains '%H'.
Of course, all necessary directories will be created.

=item C<FilePerms>

The permissions for log file. Default is 0640

=item C<DirPerms>

The permissions for directories created for log file. Default is 0750

=item C<Truncate>

If this flag have a 'true' value the log file will be truncated before
start logging. 
You will be able to change this flag using L<Truncate> method.

Default is 0 - do not truncate file.

=item C<SafeStr>

If 'true' all the 'dangerous' symbols will be printed as their hex codes.

Default is 1 - change dangerous symbols to their hex codes.

=back

In case of fatal error C<new()> returns I<C<undef>>.  I<C<$!>> variable will contain the error message.

=item C<Message($Level, $Format, @SprintfParams);>

The C<Message> method send a log string to the syslog or EventLog 
and, if allowed, to C<STDERR>.
Log string will be formed by C<sprintf> function from I<$Format> format string and
parameters passed in I<@SprintfParams>. Of course, I<@SprintfParams> could be empty
if no parameters required by format string. See C<sprintf> in C<perlfunc> for details.

The I<$Level> should be an integer and could be:

=over 4

=item Z<>

=over 4

=item C<LOG_EMERG  >

Value B<C<0>>. Will be logged as C<LOG_EMERG>  in syslog, 
as C<EVENTLOG_ERROR_TYPE> in EventLog.

=item C<LOG_ALERT  >

Value B<C<1>>. Will be logged as C<LOG_ALERT>  in syslog, 
as C<EVENTLOG_ERROR_TYPE> in EventLog.

=item C<LOG_CRIT   >

Value B<C<2>>. Will be logged as C<LOG_CRIT>   in syslog, 
as C<EVENTLOG_ERROR_TYPE> in EventLog.

=item C<LOG_ERR    >

Value B<C<3>>. Will be logged as C<LOG_ERR>     in syslog,
as C<EVENTLOG_ERROR_TYPE> in EventLog.

=item C<LOG_WARNING>

Value B<C<4>>. Will be logged as C<LOG_WARNING> in syslog,
as C<EVENTLOG_WARNING_TYPE> in EventLog.

=item C<LOG_NOTICE >

Value B<C<5>>. Will be logged as C<LOG_NOTICE>  in syslog,
as C<EVENTLOG_INFORMATION_TYPE> in EventLog.

=item C<LOG_INFO   >

Value B<C<6>>. Will be logged as C<LOG_INFO>    in syslog,
as C<EVENTLOG_INFORMATION_TYPE> in EventLog.

=item C<LOG_DEBUG  >

Value B<C<7>>. Will be logged as C<LOG_DEBUG>   in syslog,
as C<EVENTLOG_INFORMATION_TYPE> in EventLog.

=back

Default is C<LOG_INFO>.

See L<Unix::Syslog>(3) for "C<LOG_*>" description,
see L<Win32::EventLog>(3) for "C<EVENTLOG_*_TYPE>" descriptions.

=back

In case of fatal error C<Message()> returns I<C<undef>>. I<C<$!>> variable will contain the error message. 

=item C<emergency($Format, @SprintfParams);>

Just a synonym for I<C<Message(LOG_EMERG, $Format, @SprintfParams)>>

=item C<alert($Format, @SprintfParams);>

Just a synonym for I<C<Message(LOG_ALERT, $Format, @SprintfParams)>>

=item C<critical($Format, @SprintfParams);>

Just a synonym for I<C<Message(LOG_CRIT, $Format, @SprintfParams)>>

=item C<error($Format, @SprintfParams);>

Just a synonym for I<C<Message(LOG_ERR, $Format, @SprintfParams)>>

=item C<warning($Format, @SprintfParams);>

Just a synonym for I<C<Message(LOG_WARNING, $Format, @SprintfParams)>>

=item C<notice($Format, @SprintfParams);>

Just a synonym for I<C<Message(LOG_NOTICE, $Format, @SprintfParams)>>

=item C<info($Format, @SprintfParams);>

Just a synonym for I<C<Message(LOG_INFO, $Format, @SprintfParams)>>

=item C<debug($Format, @SprintfParams);>

Just a synonym for I<C<Message(LOG_DEBUG, $Format, @SprintfParams)>>

    
=item C<Level([$LogLevel]);>

If I<$LogLevel> is not specified C<Level> returns a current log level.
If I<$LogLevel> is specified C<Level> sets the log level to the new value 
and returns a previous value.

=item C<SysLog([$Flag]);>

If I<$Flag> is not specified C<SysLog> returns a current state of logging-to-system-log flag.
If I<$Flag> is specified C<SysLog> sets the logging-to-system-log flag to the new state 
and returns a previous state.

=item C<StdErr([$Flag]);>

If I<$Flag> is not specified C<StdErr> returns a current state of logging-to-STDERR flag.
If I<$Flag> is specified C<StdErr> sets the logging-to-STDERR flag to the new state 
and returns a previous state.

=item C<LogFile([$NewLogFileName, [$FilePerms]]);>

If I<$NewLogFileName> is not specified C<LogFile> returns a current log file name.
Not the "log file name template" but the actual file name.

If I<$NewLogFileName> is specified C<LogFile> sets the "log file name template"
to the I<$NewLogFileName> and returns a previous log file name (the actual file name).
The actual closing old file and opening ne one will be done during next C<Message()> call.

Note: you can specify an empty line as a I<$NewLogFileName> parameter.
It will mean "disable file logging".

=item C<Permissions([$FilePerms, [$DirPerms]]);>

If no parameters is specified C<Permissions> returns the current permissions
used for new log file creation.

If I<$FilePerms> is specified C<Permissions> sets the log file permissions
to the I<$FilePerms> and returns a previous value. 

If I<$DirPerms> is specified C<Permissions> sets the new directories permissions
to the I<$DirPerms>.

In scalar context C<Permissions> returns the previous log file permissions value.
In list context C<Permissions> returns an two-elements array, firs is original log file permissions,
second is directories permissions.

=item C<Truncate([$Flag]);>

If I<$Flag> is not specified C<Truncate> returns a current state of I<C<Truncate>> flag.
If I<$Flag> is specified C<Truncate> sets the I<C<Truncate>> flag to the new state 
and returns a previous state.

=item C<CloseLogFile([$NewLogFileName]);>

Enforce C<UniLog> to close log file temporary. It will be re-opened for next message.
If you set the C<Truncate> flag to 'true' value file will be truncated during re-opening.

=item C<Close();>

Close the logger.

=item C<SafeStr($Str);>

Just change all dangerous symbols (C<\x00-\x1F> and C<\xFF>) in a I<C<$Str>> to their
hexadecimal codes and returns the updated string.

=back

=head2 EXPORT

None by default.

=over 4

=item C<:levels>

All C<Levels>, described in the C<Message> method documentation

=item C<:options>

All C<Options>, described in the C<new> method documentation

=item C<:facilities>

All C<Facilities>, described in the C<new> method documentation

=item C<:functions>

All auxiliary functions. Just C<SafeStr()> at the moment.

=item C<SafeStr>

C<SafeStr()> function.

=item C<syslog>

Fake symbol, tells C<UniLog> to try to load the system logging module 
at the module load time.

=item C<nosyslog>

Fake symbol, tells C<UniLog> do not to try to load the system logging module 
at the module load time. The logging to Syslog/EventLog will be disabled.

If no C<syslog> nor C<nosyslog> present, C<UniLog> will try to load
the system logging module at the first C<new> method call.

=back

=head1 Known problems

=over 4

=item Problem with Perl2Exe utility.

UniLog is using external module (Unix::Syslog or Win32::Event) for actual logging.
The appropriate module is loading during runtime (in C<eval> section) so Perl2Exe
is not able to determinate this module have to be compiled in. You have to include
C<"use Unix::Syslog;"> or C<"use Win32::EventLog;"> to your script or disable syslog usage.

Uptate (Jan 10 2005): forget about Perl2Exe, use L<PAR> instead (see bundled L<pp> utility).

=back

=head1 AUTHOR

Daniel Podolsky, E<lt>tpaba@cpan.orgE<gt>

=head1 SEE ALSO

L<Unix::Syslog>, L<Win32::EventLog>, C<syslog>(3).

=cut
