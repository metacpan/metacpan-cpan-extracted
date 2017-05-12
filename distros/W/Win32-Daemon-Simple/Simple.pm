package Win32::Daemon::Simple;
use POSIX qw(strftime);
use Win32;
use Hash::Case::Preserve;
use Win32::Console qw();
use Win32::Daemon;
use FindBin qw($Bin $Script);$Bin =~ s{/}{\\}g;
use File::Spec;
use FileHandle;
use Carp;
use Exporter;
use strict;
use vars qw(@ISA @EXPORT $VERSION);
@ISA = qw(Exporter);
@EXPORT = qw(ReadParam SaveParam Log LogNT OpenLog CloseLog CatchMessages GetMessages ServiceLoop DoEvents CMDLINE SERVICEID SERVICENAME);
$VERSION = '0.2.6';

sub Now () {
	strftime( "%Y/%m/%d %H:%M:%S", localtime())
}

my $compiled = !(-e $INC{'Win32/Daemon/Simple.pm'}); # if the module was not read from disk => the script has been "compiled"
if (0) {
	require 'Win32/Service.pm';
}

my ($svcid, $origsvcid, $svcname, $svcversion) = ( $Script, $Script);
BEGIN {
	eval {
		my $title;
		if ($^C != 1 and $title = Win32::Console::_GetConsoleTitle()) {
			eval 'sub CMDLINE () {1}';
			$|=1;
			if (lc($title) eq lc($^X) or lc($title) eq lc($0)) {
				eval 'sub FROMCMDLINE () {0}';
				eval '*MsgBox = \&Win32::MsgBox;';
				if (! @ARGV) {
					push @ARGV, '-help_and_settings';
				}
			} else {
				eval 'sub FROMCMDLINE () {1}';
				eval 'sub MsgBox {}';
			}
		} else {
			eval 'sub CMDLINE () {0}';
			eval 'sub FROMCMDLINE () {0}';
			eval 'sub MsgBox {}';
		}
	};
}

my ($info, $params, $param_modify, $run_params);

# parameters
use Win32::Registry;

if ($Win32::Registry::VERSION < 0.08 and !defined($Win32::Registry2::VERSION)) {
	die "Please update your Win32::Registry to 0.08 or newer or install the patch from http://jenda.krynicky.cz/#Win32::Registry2\n\n";
}

my $ServiceKey;
{
	my $paramkey;
	sub ReadParam {
		my ( $param, $default) = @_;
		$ServiceKey = $HKLM->Open('SYSTEM\CurrentControlSet\Services\\'.$svcid)
			unless $ServiceKey;
		return $default unless $ServiceKey;
		$paramkey = $ServiceKey->Create('Parameters')
			unless $paramkey;
		my $value = $paramkey->GetValue($param);
		$value = $default unless defined $value;
		return $value;
	}

	sub SaveParam {
		my ( $param, $value) = @_;
		$ServiceKey = $HKLM->Open('SYSTEM\CurrentControlSet\Services\\'.$svcid)
			unless $ServiceKey;
		return unless $ServiceKey; # do not save anything if the service is not installed
		$paramkey = $ServiceKey->Create('Parameters')
			unless $paramkey;
		die "Can't open/create the Parameters subkey in the service settings!\n" unless $paramkey; # do not save anything if the service is not installed
		if (!defined $value) {
			$paramkey->DeleteValue($param);
		} elsif ($value =~ /^\d+$/) {
			$paramkey->SetValues($param, REG_DWORD, $value);
		} else{
			$value =~ s/\r?\n/\r\n/g;
			$paramkey->SetValues($param, REG_SZ, $value);
		}
	}
}

sub StopStartService {
	$|=1;
	my $cmd = shift;
	eval "use Win32::Service";
	my %status;
	Win32::Service::GetStatus(undef, $svcid, \%status);
	if (! %status) {
		print "\t\tThe service $svcid doesn't exist!\n";
		next;
	};
	my ($good_status,$msg);
	if ($cmd eq 'stop') {
		$good_status = 1;
		if( $status{CurrentState} == $good_status) {
			print "\n    The service did not run.\n";
			MsgBox "The service did not run.\n", MB_ICONINFORMATION, $svcname;
			return;
		}
		$msg = "stopped";
		Win32::Service::StopService(undef, $svcid);sleep(1);
	} else {
		$good_status = 4;
		if( $status{CurrentState} == $good_status) {
			print "\n    The service was running already.\n";
			MsgBox "The service was running already.\n", MB_ICONINFORMATION, $svcname;
			return;
		}
		$msg = "started";
		Win32::Service::StartService(undef, $svcid);sleep(1);
	}

	my $count=0;
	while (++$count < 120 and $status{CurrentState} != $good_status) {
		sleep(1);
		print '.';
		Win32::Service::GetStatus(undef, $svcid, \%status);
	}

	if( $status{CurrentState} == $good_status) {
		print "   The service was $msg.\n";
		MsgBox "The service was $msg.\n", MB_ICONINFORMATION, $svcname;
	} else {
		print "   The service could not be $msg.\n";
		MsgBox "The service could not be $msg.\n", MB_ICONERROR, $svcname;
	}
}

my ($logging_code,$loop_code);
# main processing
sub import {

#$::dbg->trace('main::','Win32::Daemon::Simple::');

	shift();
	my $caller_pack = caller;
	eval {
		my ($key, $val);
		while (defined ($key = shift()) and defined ($val = shift())) {
			$key = lc $key;
			if ($key eq 'service') {
				$svcid = $val;
				$origsvcid = $val;
			} elsif ($key eq 'name') {
				$svcname = $val;
			} elsif ($key eq 'version') {
				$svcversion = $val;
			} elsif ($key eq 'info') {
				$info = $val;
			} elsif ($key eq 'logging_code') {
				$logging_code = $val;
			} elsif ($key eq 'params') {
				my %params;
				tie %params, 'Hash::Case::Preserve', $val;
				$params = \%params;
			} elsif ($key eq 'run_params') {
				$run_params = $val;
			} elsif ($key eq 'param_modify') {
				$param_modify = {};
				foreach my $param (keys %$val) { # hashes are case sensitive, the param should be INsensitive!
					$param_modify->{lc $param} = $val->{$param};
				}
			} else {
				croak "Unknown option '$key' passed to use Win32::Daemon::Simple!";
			}
		}
		if (! ref $info) {
			croak "Required parameter 'info' not specified";
		};

		if (! ref $params) { $params = {} };
		if (! ref $run_params) { $run_params = {} };
		if (! ref $param_modify) { $param_modify = {} };
		unless (defined $params->{'LogFile'}) {
			my $logfile = $Bin . '\\' . $Script;
			$logfile =~ s/\.[^\.]+$/.log/ or $logfile .= '.log';
			$logfile =~ s{/}{\\}g;
			$params->{'LogFile'} = $logfile;
		} elsif ($params->{'LogFile'} !~ m{^\w:[\\/]}) {
			$params->{'LogFile'} = $Bin . '\\' . $params->{'LogFile'};
		}
		$params->{'Interval'} = 1 unless (defined $params->{'Interval'});

		if (CMDLINE) {
			Win32::Console::_SetConsoleTitle( "$svcname $svcversion (in commandline mode)");
		}

		my $run_with_params = 0;
		if ($^C != 1 and @ARGV) { # we've got some params !
			$run_with_params = 1 if (grep {$_ eq '--'} @ARGV);
			print "$svcname $svcversion\n" unless $run_with_params;
			my $inst = 0;
			my $re = join '|', map {quotemeta $_} (keys %$params);
			my $nore = qr{^[-/]no($re)$}i;
			my $defre = qr{^[-/]DEFAULT($re)$}i;
			$re = qr{^[-/]($re)(?:=(.*))?$}si;

			while (my $opt = shift(@ARGV)){
				if ($opt =~ m{^[-/]install$}i) {
					$info->{'name'} = $svcid;
					$info->{'display'} = $svcname unless defined $info->{'display'};
					if (! exists $info->{'path'}) {
						if ($compiled or $0 =~ /\.exe$/i) {
							$info->{'path'} = "$Bin\\$Script";
						} else {
							$info->{'path'} =  $^X;
							if (defined $info->{'parameters'}) {
								$info->{'parameters'} .= ' --' unless $info->{'parameters'} =~ /--$/;
								$info->{'parameters'} = "$Bin\\$Script $info->{'parameters'}";
							} else {
								$info->{'parameters'} = "$Bin\\$Script";
							}
						}
					}
					Win32::Daemon::DeleteService($svcid);
					sleep(2);
					{
						my $logdir = $params->{'LogFile'};
						$logdir =~ s{[\\/][^\\/]+$}{};
						mkdir $logdir unless -d $logdir;
					}
					if( Win32::Daemon::CreateService( $info ) ) {
						foreach my $param (keys %$params) {
							SaveParam( $param, $params->{$param});
						}
						print "    Installed successfully\n    $info->{'path'} $info->{'parameters'}\n";
						MsgBox "Installed successfully\n    $info->{'path'} $info->{'parameters'}\n", MB_ICONINFORMATION, $svcname;
					} else {
						print "    Failed to install: " . Win32::FormatMessage( Win32::Daemon::GetLastError() ) . "\n";
						MsgBox "Failed to install: " . Win32::FormatMessage( Win32::Daemon::GetLastError() ) . "\n", MB_ICONERROR, $svcname;
					}
					$inst = 1;
				} elsif ($opt =~ m{^[-/]uninstall$}i) {
					if( Win32::Daemon::DeleteService($svcid) ) {
						print "    Uninstalled successfully\n";
						MsgBox "Uninstalled successfully\n", MB_ICONINFORMATION, $svcname;
					} else {
						print "    Failed to uninstall: " . Win32::FormatMessage( Win32::Daemon::GetLastError() ) . "\n";
						MsgBox "Failed to uninstall: " . Win32::FormatMessage( Win32::Daemon::GetLastError() ) . "\n", MB_ICONERROR, $svcname;
					}
					$inst = 1;

# service settings
				} elsif ($opt =~ m{^[-/]service=(.*)$}i) {
					$svcid = $1;
					$info->{'name'} = $svcid;
					if ($info->{'parameters'}) {
						$info->{'parameters'} =~ s{[/-]service=\S+}{};
						$info->{'parameters'} = "/service=$svcid $info->{'parameters'}";
					} else {
						$info->{'parameters'} = "/service=$svcid --";
					}
				} elsif ($opt =~ m{^[-/]service:name=(.*)$}i) {
					$svcname = $1;
					$info->{'display'} = $svcname;
					if ($info->{'parameters'}) {
#						$info->{'parameters'} =~ s{[/-]service:name=\S+}{}; # what to do with quotes?
						$info->{'parameters'} = qq{"/service:name=$svcname" $info->{'parameters'}};
					} else {
						$info->{'parameters'} = qq{"/service:name=$svcname" --};
					}
					if (!$run_with_params) {
						$ServiceKey = $HKLM->Open('SYSTEM\CurrentControlSet\Services\\'.$svcid)
							unless $ServiceKey;
						$ServiceKey->SetValues('DisplayName', REG_SZ, $svcname)
							if $ServiceKey;
					}
				} elsif ($opt =~ m{^[-/]service:user=(.*)$}i) {
					$info->{'user'} = $1;
				} elsif ($opt =~ m{^[-/]service:pwd=(.*)$}i) {
					$info->{'pwd'} = $1;
				} elsif ($opt =~ m{^[-/]service:interactive=(.*)$}i) {
					$info->{'interactive'} = (($1 && lc($1) ne 'no') ? 1 : 0);

				} elsif ($opt =~ m{^[-/]start$}i) {
					StopStartService('start');
					$inst = 1;
				} elsif ($opt =~ m{^[-/]stop$}i) {
					StopStartService('stop');
					$inst = 1;
				} elsif ($opt =~ m{^[-/](?:help(?:_and_settings)?|\?)$}i) {
					my $dsc = $params->{'Description'};
					$dsc =~ s/\n/\n      /g;
					print <<"*END*";

$Script -install
  : installs the service

$Script -uninstall
  : uninstalls the service

$Script -start
  : starts the service

$Script -stop
  : stops the service

$Script -params
  : displays the effective settings

$Script -PARAM
  : changes the value of the option to 1

$Script -noPARAM
  : changes the value of the option to 0

$Script -PARAM=VALUE
  : changes the value of an option (you may specify several params at once)

  The available options:
      $dsc

*END*
					if (! FROMCMDLINE) {
						if ($opt =~ m{^[-/]help_and_settings$}i) {
							print <<'*END*';
Type "continue" and press ENTER to start processing files in commandline mode,
type "install" and press ENTER to install the service,
type "uninstall" and press ENTER to uninstall the service,
type "start" and press ENTER to start the service,
type "stop" and press ENTER to stop the service,
type "ParameterName=Value" and press ENTER to change a service parameter
or press ENTER to exit
*END*
							while (my $line = <STDIN>) {
								chomp($line);
								last if $line eq '';
								my ($param, $value) = split /=/, $line, 2;
								$param = lc $param;
								if ($param eq 'install') {
									push @ARGV, '-install';
									last;
								} elsif ($param eq 'uninstall') {
									push @ARGV, '-uninstall';
									last;
								} elsif ($param eq 'start') {
									push @ARGV, '-start';
									last;
								} elsif ($param eq 'stop') {
									push @ARGV, '-stop';
									last;
								} elsif ($param eq 'continue') {
									$run_with_params = 1;
									last;
								} elsif (exists $params->{$param}) {
									$value = 1 unless defined $value;
								} elsif (substr($param,0,2) eq 'no' and exists $params->{substr($param,2)}) {
									$param = substr($param,2);
									$value = 0 unless defined $value;
								} else {
									print "Unknown parameter '$param'!\n";
									next;
								}
								if (exists $param_modify->{$param}) {
									eval {
										$value = $param_modify->{$param}->($value);
										SaveParam( $param, $value);
										$run_params->{$param} = $value;
										print "    $param: $value\n";
									};
									if ($@) {
										print "    $param: $run_params->{$param}\n\t$@\n";
									}
								} else {
									SaveParam( $param, $value);
									$run_params->{$param} = $value;
									print "    $param: $value\n";
								}
							}
						} else {
							print "(Press ENTER to exit)\n";
							<STDIN>;
						}
					}
#					exit();
				} elsif ($opt =~ m{^[-/]params}i) {
					foreach my $param (keys %$params) {
						next if lc($param) eq 'description';
						$val = ReadParam( $param, $params->{$param});
						if ($val =~ s/\n/\n        /g) {
							print "    $param:\n        $val\n";
						} else {
							print "    $param: $val\n";
						}
					}
					print( $origsvcid ne $svcid ? "NOT INSTALLED as $svcid!\n" : "NOT INSTALLED!\n") unless $ServiceKey;
					if (! FROMCMDLINE) {
						print "(press ENTER to exit)\n";
						<STDIN>;
					}
					exit();
				} elsif ($opt =~ $re) {
					my ( $opt, $val) = ( lc($1), $2);
					$val = 1 unless defined $val;
					if (exists $param_modify->{$opt}) {
						eval {
							$val = $param_modify->{$opt}->($val);
							$run_params->{$opt} = $val;
							unless ($run_with_params) {
								print "    $opt: $val\n";
								SaveParam( $opt, $val);
							}
						};
						if ($@) {
							print "    $opt: ".ReadParam( $opt, $params->{$opt})."\n\t$@\n";
						}
					} else {
						$run_params->{$opt} = $val;
						unless ($run_with_params) {
							print "    $opt: $val\n";
							SaveParam( $opt, $val);
						}
					}
				} elsif ($opt =~ $nore) {
					my ( $opt) = lc($1);
					my $val = 0;
					if (exists $param_modify->{lc $opt}) {
						eval {
							$val = $param_modify->{lc $opt}->($val);
							$run_params->{$opt} = $val;
							unless ($run_with_params) {
								print "    $opt: $val\n";
								SaveParam( $opt, $val);
							}
						};
						if ($@) {
							print "    $opt: $@\n";
						}
					} else {
						$run_params->{$opt} = $val;
						unless ($run_with_params) {
							print "    $opt: $val\n";
							SaveParam( $opt, $val);
						}
					}
				} elsif ($opt =~ $defre) {
					my ( $opt) = lc($1);
					my $val = $params->{$opt};
					$run_params->{$opt} = $val;
					unless ($run_with_params) {
						print "    $opt: -DEFAULT-VALUE-\n";
						SaveParam( $opt, $val);
					}
				} elsif ($opt =~ m{^[-/]default$}i) {
					if ($run_with_params) {
						foreach my $param (keys %$params) {
							$run_params->{lc $param} = $params->{$param};
						}
					} else {
						foreach my $param (keys %$params) {
							SaveParam( $param, $params->{$param});
							next if lc($param) eq 'description';
							my $val = $params->{$param};
							if ($val =~ s/\n/\n        /g) {
								print "    $param:\n        $val\n";
							} else {
								print "    $param: $val\n";
							}
						}
					}
				} elsif ($opt eq '--') {
					die "\$run_with_params was not set !!!" unless $run_with_params; # this should already be set!
					last;
				} else {
					MsgBox "Unknown option '$opt'", MB_ICONEXCLAMATION, $svcname;
					$inst = 1;
				}
			}
			MsgBox "Changed the options", MB_ICONINFORMATION, $svcname
				unless CMDLINE or $inst or $run_with_params;
			exit if ($inst or !$run_with_params); # if we have params
		}

		eval $logging_code; die "$@\n" if $@;
		$logging_code = '';

		if (!$^C) {
			Win32::Daemon::StartService();

			if (CMDLINE) {
				no warnings qw(redefine);
				eval "sub Win32::Daemon::State {&SERVICE_START_PENDING}";
			}

			while( SERVICE_START_PENDING != Win32::Daemon::State() ) {
				sleep( 1 );
			}

			if (CMDLINE) {
				no warnings qw(redefine);
				eval "sub Win32::Daemon::State {&SERVICE_RUNNING}";
			}

			LogStart("\n$svcname ver. $svcversion started");

			Win32::Daemon::State( SERVICE_RUNNING );

			OpenLog();
			LogNT("Read params");
			{
				local $^W;
				no strict 'refs';
				my $val;
				foreach my $param (keys %$params) {
					my $sub = uc $param;
					if (exists $run_params->{lc $param}) {
						$val = $run_params->{lc $param};
					} else {
						$val = ReadParam( $param, $params->{$param});
					}
					LogNT("\t$param: $val") unless lc($param) eq 'description';
					if (! defined $val) {
						eval "sub $sub () {undef}";
					} elsif ($val =~ /^\d+(?:\.\d+)?$/) { # if it looks like a number it IS a number
						$val += 0;
						eval "sub $sub () {$val}";
					} else {
						$val =~ s{(['\\])}{\\$1}g;
						eval "sub $sub () {'$val'}";
					}
					push @EXPORT, $sub;
				}
				eval "sub SERVICEID () {q\\$svcid\\}";
				eval "sub SERVICENAME () {q\\$svcname\\}";
			}
			LogNT('Running');
			CloseLog();
			eval $loop_code; die "$@\n" if $@;
			$loop_code = '';
		} else {
			foreach my $param (keys %$params) {
				my $sub = uc $param;
				eval "sub $sub () {}";
				push @EXPORT, $sub;
			}
			eval "sub SERVICEID () {q\\$svcid\\}";
			eval "sub SERVICENAME () {q\\$svcname\\}";
		}
	};
	if ($@) {
		if (CMDLINE) {
			die "ERROR in use Win32::Daemon::Simple: $@\n";
		} elsif ($params->{'LogFile'}) {
			Log("ERROR in use Win32::Daemon::Simple: $@");
			exit;
		} elsif ($svcid) {
			SaveParam("ERROR", $@);
			exit;
		} else {
			exit(); # don't have a way to report the problem. The person should have tried it in commandline mode first.
		}
	} elsif (! $^C) { # if not being compiled
		SaveParam("ERROR", undef);
	};

	Win32::Daemon::Simple->export_to_level( 1, $caller_pack, @EXPORT);
}

$loop_code = <<'-END--';
my $PrevState = SERVICE_START_PENDING;
sub SetState ($) {
	Win32::Daemon::State($_[0]);
	$PrevState = $_[0];
}

END {
	Win32::Daemon::State(SERVICE_STOPPED) unless $PrevState == SERVICE_STOPPED;
}

sub ServiceLoop {
	my $process = shift();
	my $cnt = 1;
	my $tick_cnt = 60;
	my $state;
	while (1) {
		$state = Win32::Daemon::State();
		if ($state == SERVICE_RUNNING or $state == 0x0080) {
			# RUNNING
			if ($state == 0x0080) {
				SetState(SERVICE_RUNNING);
			}

			# Check for any outstanding commands. Pass in a non zero value
			# and it resets the Last Message to SERVICE_CONTROL_NONE.
			if ( SERVICE_CONTROL_NONE != ( my $Message = Win32::Daemon::QueryLastMessage( 1 ))) {
				if ( SERVICE_CONTROL_INTERROGATE == $Message ) {
					# Got here if the Service Control Manager is requesting
					# the current state of the service. This can happen for
					# a variety of reasons. Report the last state we set.
					Win32::Daemon::State( $PrevState );
				} elsif ( SERVICE_CONTROL_SHUTDOWN == $Message ) {
					# Yikes! The system is shutting down. We had better clean up
					# and stop.
					# Tell the SCM that we are preparing to shutdown and that we expect
					# it to take 25 seconds (so don't terminate us for at least 25 seconds)...
					Win32::Daemon::State( SERVICE_STOP_PENDING, 25000 );
				} else {
					# Got an unhandled control message. Set the state to
					# whatever the previous state was.
					Log("Unhandled service message: $Message");
					Win32::Daemon::State( $PrevState );
				}
			}

			if (--$cnt == 0) {
				print "       \r" if CMDLINE;
				$cnt = int(INTERVAL * 60);
				eval {$process->()};
				if ($@) {
					Log("ERROR: $@");
					LogNT;
				}
			}
			if (TICK and (--$tick_cnt == 0)) {
				LogNT('tick: '.Now()) ;
				$tick_cnt = 60;
			}
			print "\r$cnt      \r" if CMDLINE;
			sleep 1;
			# /RUNNING
		} elsif ($state == SERVICE_PAUSE_PENDING) {
			SetState(SERVICE_PAUSED);
			Log("Paused");
		} elsif ($state == SERVICE_PAUSED) {
			sleep 10;
		} elsif ($state == SERVICE_CONTINUE_PENDING) {
			SetState(SERVICE_RUNNING);
			Log("Continue");
		} elsif ($state == SERVICE_STOP_PENDING or $state == SERVICE_STOPPED) {
			SetState(SERVICE_STOPPED);
			Log("Asked to stop");
			last;
		} else {
			Log("Unexpected state : $state");
			last;
		}
	}

	Win32::Daemon::StopService();
}

sub DoHandler {
	my ($handler, $do) = @_;
	if (defined $handler) {
		if (ref $handler) {
			if ($handler->(1)) {
				$do->();
				return 1;
			}
		} elsif ($handler) {
			$do->();
			return 1;
		}
		return;
	}
	$do->();
	return 1;
}

sub DoEvents { # (\&PauseProc, \&UnpauseProc, \&StopProc)
	my $state = Win32::Daemon::State();
	if ($state == SERVICE_RUNNING or $state == 0x0080) {
		# RUNNING
		if ($state == 0x0080) {
			Win32::Daemon::SetState(SERVICE_RUNNING);
		}

		# Check for any outstanding commands. Pass in a non zero value
		# and it resets the Last Message to SERVICE_CONTROL_NONE.
		if ( SERVICE_CONTROL_NONE != ( my $Message = Win32::Daemon::QueryLastMessage( 1 ))) {
			if ( SERVICE_CONTROL_INTERROGATE == $Message ) {
				# Got here if the Service Control Manager is requesting
				# the current state of the service. This can happen for
				# a variety of reasons. Report the last state we set.
				Win32::Daemon::State( $PrevState );
			} elsif ( SERVICE_CONTROL_SHUTDOWN == $Message ) {
				# Yikes! The system is shutting down. We had better clean up
				# and stop.
				# Tell the SCM that we are preparing to shutdown and that we expect
				# it to take 25 seconds (so don't terminate us for at least 25 seconds)...
				Log("Asked to stop (The server's going down!)");
				Win32::Daemon::State( SERVICE_STOP_PENDING, 25000 );
				DoHandler( $_[2], sub {Win32::Daemon::StopService();Log("Going down");exit;});
			} else {
				# Got an unhandled control message. Set the state to
				# whatever the previous state was.
				Log("Unhandled service message: $Message");
				Win32::Daemon::State( $PrevState );
			}
		}
		return SERVICE_RUNNING;
		# /RUNNING
	} elsif ($state == SERVICE_PAUSE_PENDING) {
		if (DoHandler( $_[0], sub {SetState(SERVICE_PAUSED);Log("Paused")})) {
			return Pause(@_[1,2]);
		} else {
			return SERVICE_PAUSE_PENDING;
		}
	} elsif ($state == SERVICE_PAUSED) {
		return Pause(@_[1,2]);
	} elsif ($state == SERVICE_CONTINUE_PENDING) {
		SetState(SERVICE_RUNNING);
		Log("Continue");
		$_[1]->() if (defined $_[1] and ref $_[1] eq 'CODE');
	} elsif ($state == SERVICE_STOP_PENDING or $state == SERVICE_STOPPED) {
		Log("Asked to stop");
		DoHandler( $_[2], sub {Win32::Daemon::StopService();Log("Going down");exit;});
		return SERVICE_STOP_PENDING;
	} else {
		Log("Unexpected state : $state");
		return $state
	}
}

sub Pause {
	my $state;
	while (1) {
		sleep(5);
		$state = Win32::Daemon::State();
		next if $state == SERVICE_PAUSED;

		if ($state == SERVICE_STOP_PENDING or $state == SERVICE_STOPPED) {
			Log("Asked to stop");
			DoHandler( $_[1], sub {Win32::Daemon::StopService();Log("Going down");exit;});
			return SERVICE_STOP_PENDING;
		} else {
			# unpausing
			Log("Continue");
			$_[0]->() if (defined $_[0] and ref $_[0] eq 'CODE');
			SetState(SERVICE_RUNNING);
			return SERVICE_RUNNING
		}
	}
}

-END--

# logging
$logging_code = <<'-END--';
{
	my $logfile;
	my $catchmessages = 0;
	my $messages = '';
	my $LOG = new FileHandle;
	sub LogStart {
		$logfile = $run_params->{'logfile'} || ReadParam('LogFile', $params->{'LogFile'})
			unless $logfile;
		open $LOG, ">> $logfile";
		print $LOG @_, " at ", Now(),"\n";
		print STDOUT @_,"\n" if CMDLINE;
		close $LOG;
	}
	sub Log {
		my $had_to_open = 0;
		if (! $LOG->opened()) {
			$had_to_open = 1;
			unshift @_, "$svcname $svcversion\n"
				unless -e $logfile;
			open $LOG, ">> $logfile";
		}
		print $LOG @_, " at ", Now(),"\n";
		$messages .= join '', @_,"\n"
			if $catchmessages;
		print STDOUT @_,"\n"
			if CMDLINE;
		close $LOG
			if $had_to_open;
	}
	sub LogNT {
		my $had_to_open = 0;
		if (! $LOG->opened()) {
			$had_to_open = 1;
			unshift @_, "$svcname $svcversion\n"
				unless -e $logfile;
			open $LOG, ">> $logfile";
		}
		print $LOG @_,"\n";
		$messages .= join '', @_,"\n"
			if $catchmessages;
		print STDOUT @_,"\n"
			if CMDLINE;
		close $LOG
			if $had_to_open;
	}
	sub OpenLog () {
		if (! $LOG->opened()) {
			$logfile = ReadParam('LogFile', $params->{'LogFile'})
				unless $logfile;
			my $existed = -e $logfile;
			open $LOG, ">> $logfile";
			print $LOG "$svcname $svcversion\n"
				unless $existed;
		}
	}
	sub CloseLog () {
		close $LOG if $LOG->opened();
	}
	sub CatchMessages {
		$catchmessages = shift();
		$messages = '';
	}
	sub GetMessages {
		my $msg = $messages;
		$messages = '';
		return $msg;
	}
	sub RedirectLog {
		$logfile = shift();
	}
}
-END--


1;

__END__
=head1 NAME

Win32::Daemon::Simple - framework for Windows services

0.2.5

=head1 SYNOPSIS

	use FindBin qw($Bin $Script);
	use File::Spec;
	use Win32::Daemon::Simple
		Service => 'SERVICENAME',
		Name => 'SERVICE NAME',
		Version => 'x.x',
		Info => {
			display =>  'SERVICEDISPLAYNAME',
			description => 'SERVICEDESCRIPTION',
			user    =>  '',
			pwd     =>  '',
			interactive => 0,
	#		parameters => "-- foo bar baz",
		},
		Params => { # the default parameters
			Tick => 0,
			Talkative => 0,
			Interval => 10, # minutes
			LogFile => "ServiceName.log",
			# ...
			Description => <<'*END*',
	Tick : (0/1) controls whether the service writes a "tick" message to
	  the log once a minute if there's nothing to do
	Talkative : controls the amount of logging information
	Interval : how often does the service look for new or modified files
	  (in minutes)
	LogFile : the path to the log file
	...
	*END*
		},
		Param_modify => {
			LogFile => sub {File::Spec->rel2abs($_[0])},
			Interval => sub {
				no warnings;
				my $interval = 0+$_[0];
				die "The interval must be a positive number!\n"
					unless $interval > 0;
				return $interval
			},
			Tick => sub {return ($_[0] ? 1 : 0)},
		},
		Run_params => { # parameters for this run of the service
			#...
		};

	# initialization

	ServiceLoop(\&doTheJob);

	# cleanup

	Log("Going down");
	exit;

	# definition of doTheJob()
	# You may want to call DoEvents() within the doTheJob() at places where it
	# would be safe to pause or stop the service if the processing takes a lot of time.
	# Eg. DoEvents( \&close_db, \&open_db, sub {close_db(); cleanup();1})

=head1 DESCRIPTION

This module will take care of the instalation/deinstalation, reading, storing and modifying parameters,
service loop with status processing and logging. It's a simple to use framework for services that need
to wake up from time to time and do its job and otherwise should just poll the service status and sleep
as well as services that watch something and poll the Service Manager requests from time to time.

You may leave the looping to the module and only write a procedure that will be called in the specified
intervals or loop yourself and allow the module to process the requests when it fits you.

This module should allow you to create your services in a simple and consistent way. You just provide the
service name and other settings and the actuall processing, the service related stuff and commandline
parameters are taken care off already.

=head2 use Win32::Daemon::Simple

All the service parameters are passed to the module via the use statement. This allows the module to fetch
the service parameters before your script gets compiled, set the constants according to the parameters and
to the way the script was started. Thanks to this Perl will be able to inline the constant values and optimize out
statements that are not needed. Eg:

	print "This will print only if you start the script on cmd line.\n"
		if CMDLINE;

=head3 Service

The internal system name of the service (for example "w3svc"). The service parameters
will be stored in the registry in HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$Service.

=head3 Name

The name of the service as it will be printed into the log file and to the screen when
installing/uninstalling/modifying the service.

=head3 Version

The version number. This will be printed to the screen and log files and used by PDKcompile to set
the version info of the EXE generated by PerlApp.

=head3 Info

This is a hash that is with minor changes passed to the Win32::Daemon::CreateService.

=head4 display

The display name of the service. This is the name that will be displayed in the Service Manager.
Eg. "World Wide Web Publishing Service".

=head4 description

The description displayed alongside the display name in the Service Manager.

=head4 user

=head4 pwd

The username and password that the service will be running under.
The accont must have the SeServiceLogonRight right. You can change user rights
using Win32::Lanman::GrantPrivilegeToAccount() or the User Manager.

=head4 interactive

Whether or not is the service supposed to run interactive (visible to whoever is logged on the server's console).

=head4 path

The path to the script/program to run. This should either be full path to Perl, space and full path to your raw script
OR a full path to the EXE created by PerlApp or Perl2Exe. This option will be set properly by the module and you
should never specify it yourself. You should really know what you are doing and what before you do.

=head4 parameters

The "command line" parameters that are to be passed to the service. Please see below for the explanation of
commandline parameter processing !!!

=head3 Params

This hash specifies the parameters that the service uses and their DEFAULT values.
When the service is installed these values will be stored in the registry
(under HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$Service\Parameters)
and whenever the service starts the current values will be read and the module will define a constant
for each of the subkeys.

Some of the parameters are used by the Win32::Daemon::Simple itself, so they should be always present.

=head4 Tick

Controls whether the module prints

	"tick: " . strftime( "%Y/%m/%d %H:%M:%S", localtime()) . "\n"

into the log file once a minute. (So that you could see that the service did not hang, but just doesn't have anything to do.)
The ticking will be done only if you let the module do the looping (see C<ServiceLoop> below).

If you do not specify this parameter here it will always be OFF.

=head4 Interval

Specifies how often should the module call your callback subroutine (see C<ServiceLoop> below).
In minutes, though it doesn't have to be a whole number, you can specify interval=0.5.
The module will not call your callback more often than once a second though!

Not necessary if you do the looping yourself.

=head4 LogFile

The path to the log file. You should include this parameter so that the user will be able to change the path where
the logging information is written. Currently it's not possible to turn the loggin off except by overwriting
the C<Logging_code>.

If you do not specify this parameter or use C<undef> then the log file will be created in the same directory as the script
and named ScriptName.log.

=head4 Description

This value of this parameter is included in the help printed when the script is executed with -help parameter.
It should describe the various parameters that you can set for the service.

The values of these options are available as TICK, INTERVAL, LOGFILE and DESCRIPTION constants.

=head3 Param_modify

Here you may specify what functions to call when the user tries to update a service parameter.
The function may modify or reject the new value. If you want to reject a value die("with the message\n"),
otherwise return the value you want to be stored in the registry and used by the service.

		Param_modify => {
			LogFile => sub {File::Spec->rel2abs($_[0])},
			Interval => sub {
				no warnings;
				my $interval = 0+$_[0];
				die "The interval must be a positive number!\n"
					unless $interval > 0;
				return $interval;
			},
			Tick => sub {return ($_[0] ? 1 : 0)},
			SMTP => sub {
				my $smtp = shift;
				return $smtp if Mail::Sender::TestServer($smtp);
				# assuming you have Mail::Sender 0.8.07 or newer
			},
		},

=head3 Logging_code

(ADVANCED) This option allows you to overwrite the functions that will be used for logging.
You can log into the EvenLog or whereever you like.

		Logging_code => <<'*END*',
	sub LogStart {};	# called once when the service starts
	sub Log {};		# called many times. Appends a timestamp.
	sub LogNT {};		# called many times. Doesn't append a timestamp.
	sub OpenLog {};	# called once, just before printing the params
	sub CloseLog {};	# called once, just after printing the params
	sub CatchMessages {}; # not caled by Win32::Daemon::Simple
	sub GetMessages {}; # not caled by Win32::Daemon::Simple
	*END*

See below for more information about the functions.

=head3 Run_params

(ADVANCED) Here you can overwrite the service parameters. The values specified here take precedence over
the values stored in the registry or specified in Params=> hash.

	Run_params => {
		LogFile => (condition ? "$Bin\\Foo.log" : "$Bin\\Bar.log"),
	}

=head2 Exported functions

=head3 ServiceLoop

	ServiceLoop( \&processing)

Starts the event processing loop. The subroutine you pass will be called in the specified
intervals.

In the loop the module tests the service status and processes requests from Service Manager, ticks
(writes "Tick at $TimeStamp" messages once a minute if the Tick parameter is set) and calls your callback
if the interval is out. Then it will sleep(1).

=head3 DoEvents

	DoEvents()
	DoEvents( $PauseProc, $UnPauseProc, $StopProc)

You may call this procedure at any time to process the requests from the Service Manager.
The first parameter specifies what is to be done if the service is to be paused, the second
when it has to continue and the third when it's asked to stop.

If $PauseProc is:

	undef : the service is automaticaly paused,
		DoEvents() returns after the Service Manager asks it to continue
	not a code ref and true : the service is automaticaly paused,
		DoEvents() returns after the Service Manager asks it to continue
	not a code ref and false : the service is not paused,
		DoEvents() returns SERVICE_PAUSE_PENDING immediately.
	a code reference : the procedure is executed. If it returns true
		the service is paused and DoEvents() returns after the service
		manager asks the service to continue, if it returns false DoEvents()
		returns SERVICE_PAUSE_PENDING.

If $UnpauseProc is:

	a code reference : the procedure will be executed when the service returns from
		the paused state.
	anything else : nothing will be done

If $StopProc is:

	undef : the service is automaticaly stopped and
		the process exits
	not a code ref and true : the service is automaticaly stopped and
		the process exits
	not a code ref and false : the service is not stopped,
		DoEvents() returns SERVICE_STOP_PENDING immediately.
	a code reference : the procedure is executed. If it returns true
		the service is stopped and the process exits, if it returns false DoEvents()
		returns SERVICE_PAUSE_PENDING.

=head3 Pause

	Pause()
	Pause($UnPauseProc, $StopProc)

If the DoEvents() returned SERVICE_PAUSE_PENDING you should do whatever you need
to get the service to a pausable state (close open database connections etc.) and
call this procedure. The meanings of the parameters is the same as for DoEvents().

=head3 Log

Writes the parameters to the log file (and in commandline mode also to the console).
Appends " at $TimeStamp\n" to the message.

=head3 LogNT

Writes the parameters to the log file (and in command line mode also to the console).
Only appends the newline.

=head3 ReadParam

	$value = ReadParam( $paramname, $default);

Reads the value of a parameter stored in
HKLM\SYSTEM\CurrentControlSet\Services\SERVICENAME\Parameters
If there is no value with that name returns the $default.

=head3 SaveParam

	SaveParam( $paramname, $value);

Stores the new value of the parameter in
HKLM\SYSTEM\CurrentControlSet\Services\SERVICENAME\Parameters.

=head3 CatchMessages

	CatchMessages( $boolean);

Turns on or off capturing of messages passed to Log() or LogNT(). Clears the buffer.

=head3 GetMessages

	$messages = GetMessages();

Returns the messages captured since CatchMessages(1) or last GetMessages(). Clears the buffer.

These two functions are handy if you want to mail the result of a task. You just CatchMessages(1) when you start
the task and GetMessages() and CatchMessages(0) when you are done.

=head3 CMDLINE

Constant. If set to 1 the service is running in the command line mode, otherwise set to 0.

=head3 PARAMETERNAME

For each parameter specified in the C<params=>{...}> option the module reads
the actual value from the registry (using the value from the C<params=>{...}> option
as a default) and defines a constant named C<uc($parametername)>.

=head2 Service parameters

The parameters passed to a script using this module will be processed by the module!
If you want to pass some paramters to the script itself use -- as a parameter.
If you do then the parameters before the -- will be processed by the module and the ones behind
will be passed to the script. If you do not use the -- but do call the program with some parameters
then the parameters will be processed by Win32::Daemon::Simple and your program will end!
You may use either -param or /param. This makes no difference.

The service created using this module will accept the following commandline parameters:

=head3 -install

Installs the service and stores the default values of the parameters to the registry into
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\ServiceName\Parameters

If you get an error like

	Failed to install: The specified service has been marked for deletion.

or

	Failed to install: The specified service already exists.

close the Services window and/or the regedit and try again!

=head3 -uninstall

Uninstalls the service.

=head3 -start

Starts the service.

=head3 -stop

Stops the service.

=head3 -params

Prints the actual values of all the parameters of the service.

=head3 -help

Prints the name and version of the service and the list of options.
If the parameters=>{} option contained a Description, then the Description is printed as well.

=head3 -default

Sets all parameters to their default values.

=head3 -PARAM

Sets the value of PARAM to 1. The parameter names are case insensitive.

=head3 -noPARAM

Sets the value of PARAM to 0. The parameter names are case insensitive.

=head3 -PARAM=value

Sets the value of PARAM to value. The parameter names are case insensitive.

You may validate and/or modify the value with a handler specified in the
Param_modify=>{} option. If the handler die()s the value will NOT be changed
and the error message will be printed to the screen.

=head3 -defaultPARAM

Deletes the parameter from registry, therefore the default value of that parameter
will be used each time the service starts.

=head3 -service=name

Let's you overwrite the service ID specified in the

	use Win32::Daemon::Simple
		Service => 'TestSimpleService',

If you use this BEFORE -install, the service will be installed into
HKLM\SYSTEM\CurrentControlSet\Services\[$name]

This allows you to install several instances of a service, each under a different name.
Each instance will remember its name which you can access as C<SERVICEID>.

If you want to change the parameters of one of the instances use

	service.pl -service=name -tick -logfile=name.log

without the -service parameter you are chaning the default service.

=head3 -service:name=name

Let's you overwrite the service display name and the name written to the log file.
That is both

	use Win32::Daemon::Simple
		...
		Name => 'Long Service Name',
		...
		Info => {
			display =>  'Display Service Name',

You may get the name as C<SERVICENAME>.

=head3 -service:user=.\localusername

=head3 -service:pwd=password

You can specify what user account to use for the service. These parameters are ONLY effective
if followed by C<-install> !

=head3 -service:interactive=0/1

Let's you specify whether the service is allowed to interact with the desktop.
This parameter is ONLY effective if followed by C<-install> and if you do not specify the C<user> and C<pwd>!

=head3 --

Stop processing parameters, run the script and leave the rest of @ARGV intact.
The -install, -uninstall, -stop, -start, -help and -params parameters cannot be used
before the --.

If the service parameters contain -- then all the -param, -noparam, -param=value,
-defaultparam and -default only affect the current run and are not written into the registry.


=head3 Examples

	script.pl -install

Installs the script.pl as a service with the default parameters.

	script.pl -uninstall

Uninstalls the service.

	script.pl -tick -interval=10

Changes the options in the registry. When the service starts next time it will tick and the callbacl will be called
each 10 minutes.

	script.pl -notick -interval=5 --

Start the service without ticking and with the interval of 5 minutes. Do not make any changes to the registry.

	script.pl -interval=60 -start

Set the interval to 60 minutes in the registry, start the service (via the service manager) and exit.

	script.pl -- foo fae fou

Start the service and set @ARGV = qw(foo fae fou).

=head2 Comments

The scripts using this module are sensitive to the way they were started.

If you start them with a parameter they process that parameter as explained above.
Then if you started them from the Run dialog or by doubleclicking they print
(press ENTER to continue) and wait for the user to press enter, if you started them from
the command prompt they exit immediately

If they are started without parameters or with -- by the Service Manager they register with
the Manager and start your code passing it whatever parameters you specified after the --,
if they are started without parameters from command prompt
they start working in a command line mode (all info is printed to the screen as well as to the log file)
and if they are started by doubleclicking on the script they show the -help screen.

=head2 To do

-install=name
	A way to override the service name set by the script. I  will have to append
	-s_v_c_n_a_m_e=name to the service parameters!
	Needed for ability to run several instances of a service.

=head1 AUTHOR

 Jenda@Krynicky.cz
 http://Jenda.Krynicky.cz

 With comments and suggestions by extern.Lars.Oeschey@audi.de

=head1 SEE ALSO

L<Win32::Daemon>.

=cut
