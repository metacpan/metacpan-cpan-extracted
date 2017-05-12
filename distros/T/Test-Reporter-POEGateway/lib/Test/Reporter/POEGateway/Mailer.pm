# Declare our package
package Test::Reporter::POEGateway::Mailer;
use strict; use warnings;

# Initialize our version
use vars qw( $VERSION );
$VERSION = '0.04';

# Import what we need from the POE namespace
use POE;
use POE::Wheel::Run;
use POE::Filter::Reference;
use POE::Filter::Line;
use base 'POE::Session::AttributeBased';

# Set some constants
BEGIN {
	if ( ! defined &DEBUG ) { *DEBUG = sub () { 0 } }
}

# starts the component!
sub spawn {
	my $class = shift;

	# The options hash
	my %opt;

	# Support passing in a hash ref or a regular hash
	if ( ( @_ & 1 ) and ref $_[0] and ref( $_[0] ) eq 'HASH' ) {
		%opt = %{ $_[0] };
	} else {
		# Sanity checking
		if ( @_ & 1 ) {
			warn __PACKAGE__ . ' requires an even number of options passed to spawn()';
			return 0;
		}

		%opt = @_;
	}

	# lowercase keys
	%opt = map { lc($_) => $opt{$_} } keys %opt;

	if ( exists $opt{'poegateway'} ) {
		if ( DEBUG ) {
			warn "Not using REPORTS, we will receive reports directly from POEGateway";
		}

		if ( exists $opt{'reports'} ) {
			warn "You cannot use REPORTS with POEGATEWAY at the same time, preferring POEGATEWAY!";
			delete $opt{'reports'};
		}
	} else {
		# setup the path to read reports from
		if ( ! exists $opt{'reports'} or ! defined $opt{'reports'} ) {
			require File::Spec;
			my $path = File::Spec->catdir( $ENV{HOME}, 'cpan_reports' );
			if ( DEBUG ) {
				warn "Using default REPORTS = $path";
			}

			# Set the default
			$opt{'reports'} = $path;
		}

		# validate the report path
		if ( ! -d $opt{'reports'} ) {
			warn "The REPORTS path does not exist ($opt{'reports'}), please make sure it is a writable directory!";
			return 0;
		}

		# setup the dirwatch alias
		if ( ! exists $opt{'dirwatch_alias'} or ! defined $opt{'dirwatch_alias'} ) {
			if ( DEBUG ) {
				warn 'Using default DIRWATCH_ALIAS = POEGateway-Mailer-DirWatch';
			}

			# Set the default
			$opt{'dirwatch_alias'} = 'POEGateway-Mailer-DirWatch';
		}

		# setup the dirwatch interval
		if ( ! exists $opt{'dirwatch_interval'} or ! defined $opt{'dirwatch_interval'} ) {
			if ( DEBUG ) {
				warn 'Using default DIRWATCH_INTERVAL = 120';
			}

			# Set the default
			$opt{'dirwatch_interval'} = 120;
		}
	}

	# setup the alias
	if ( ! exists $opt{'alias'} or ! defined $opt{'alias'} ) {
		if ( DEBUG ) {
			warn 'Using default ALIAS = POEGateway-Mailer';
		}

		# Set the default
		$opt{'alias'} = 'POEGateway-Mailer';
	}

	# Setup the session
	if ( ! exists $opt{'session'} or ! defined $opt{'session'} ) {
		if ( DEBUG ) {
			warn 'Using default SESSION = caller';
		}

		# set the default
		$opt{'session'} = undef;
	} else {
		# Convert it to an ID
		if ( UNIVERSAL::isa( $opt{'session'}, 'POE::Session' ) ) {
			$opt{'session'} = $opt{'session'}->ID;
		}
	}

	# setup the "maildone" event
	if ( ! exists $opt{'maildone'} or ! defined $opt{'maildone'} ) {
		if ( DEBUG ) {
			warn 'Using default MAILDONE = undef';
		}

		# Set the default
		$opt{'maildone'} = undef;
	}

	# setup the mailing subprocess
	if ( ! exists $opt{'mailer'} or ! defined $opt{'mailer'} ) {
		if ( DEBUG ) {
			warn 'Using default MAILER = SMTP';
		}

		# Set the default
		$opt{'mailer'} = 'SMTP';
	} else {
		# TODO verify the mailer actually exists?
	}

	# setup the mailing subprocess config
	if ( ! exists $opt{'mailer_conf'} or ! defined $opt{'mailer_conf'} ) {
		if ( DEBUG ) {
			warn 'Using default MAILER_CONF = {}';
		}

		# Set the default
		$opt{'mailer_conf'} = {};
	} else {
		if ( ref( $opt{'mailer_conf'} ) ne 'HASH' ) {
			warn "The MAILER_CONF argument is not a valid HASH reference!";
			return 0;
		}
	}

	# setup the host aliases
	if ( ! exists $opt{'host_aliases'} or ! defined $opt{'host_aliases'} ) {
		if ( DEBUG ) {
			warn 'Using default HOST_ALIASES = {}';
		}

		# Set the default
		$opt{'host_aliases'} = {};
	} else {
		if ( ref( $opt{'host_aliases'} ) ne 'HASH' ) {
			warn "The HOST_ALIASES argument is not a valid HASH reference!";
			return 0;
		}
	}

	# setup the delay between emails
	if ( ! exists $opt{'delay'} or ! defined $opt{'delay'} ) {
		if ( DEBUG ) {
			warn 'Using default DELAY = 0';
		}

		# Set the default
		$opt{'delay'} = 0;
	} else {
		if ( $opt{'delay'} !~ /^\d+$/ ) {
			warn 'The DELAY argument is not a valid integer >= 0!';
			return 0;
		}
	}

	# Create our session
	POE::Session->create(
		__PACKAGE__->inline_states(),
		'heap'	=>	{
			'ALIAS'			=> $opt{'alias'},
			'MAILER'		=> $opt{'mailer'},
			'MAILER_CONF'		=> $opt{'mailer_conf'},
			'HOST_ALIASES'		=> $opt{'host_aliases'},
			'DELAY'			=> $opt{'delay'},

			'SESSION'		=> $opt{'session'},
			'MAILDONE'		=> $opt{'maildone'},

			( exists $opt{'poegateway'} ? ( 'POEGATEWAY' => 1 ) : (
				'REPORTS'		=> $opt{'reports'},
				'DIRWATCH_ALIAS'	=> $opt{'dirwatch_alias'},
				'DIRWATCH_INTERVAL'	=> $opt{'dirwatch_interval'},
			) ),

			'NEWFILES'		=> [],
			'WHEEL'			=> undef,
			'WHEEL_WORKING'		=> 0,
			'WHEEL_RETRIES'		=> 0,
			'SHUTDOWN'		=> 0,
		},
	);

	# return success
	return 1;
}

# This starts the component
sub _start : State {
	if ( DEBUG ) {
		warn 'Starting alias "' . $_[HEAP]->{'ALIAS'} . '"';
	}

	# Set up the alias for ourself
	$_[KERNEL]->alias_set( $_[HEAP]->{'ALIAS'} );

	# spawn the dirwatch
	if ( ! exists $_[HEAP]->{'POEGATEWAY'} ) {
		require POE::Component::DirWatch;
		POE::Component::DirWatch->import;	# needed to set AIO stuff, darn it!
		$_[HEAP]->{'DIRWATCH'} = POE::Component::DirWatch->new(
			'alias'		=> $_[HEAP]->{'DIRWATCH_ALIAS'},
			'directory'	=> $_[HEAP]->{'REPORTS'},
			'file_callback'	=> $_[SESSION]->postback( 'got_new_file' ),
			'interval'	=> $_[HEAP]->{'DIRWATCH_INTERVAL'},
		);

		# Load the necessary modules
		require YAML::Tiny;
		YAML::Tiny->import( qw( LoadFile ) );

		require File::Copy;
		File::Copy->import( qw( move ) );

		require File::Spec;
	}

	# Setup the session
	if ( ! defined $_[HEAP]->{'SESSION'} and defined $_[HEAP]->{'MAILDONE'} ) {
		# Use the sender
		if ( $_[KERNEL] == $_[SENDER] ) {
			warn 'Not called from another POE session and SESSION was not set!';
			$_[KERNEL]->yield( 'shutdown' );
			return;
		} else {
			$_[HEAP]->{'SESSION'} = $_[SENDER]->ID;
		}
	}

	# Give it a refcount
	if ( defined $_[HEAP]->{'SESSION'} ) {
		$_[KERNEL]->refcount_increment( $_[HEAP]->{'SESSION'}, __PACKAGE__ );
	}

	return;
}

# POE Handlers
sub _stop : State {
	if ( DEBUG ) {
		warn 'Stopping alias "' . $_[HEAP]->{'ALIAS'} . '"';
	}

	return;
}

sub _child : State {
	return;
}

sub shutdown : State {
	if ( DEBUG ) {
		warn "Shutting down alias '" . $_[HEAP]->{'ALIAS'} . "'";
	}

	# cleanup some stuff
	$_[KERNEL]->alias_remove( $_[HEAP]->{'ALIAS'} );

	# tell dirwatcher to shutdown
	if ( exists $_[HEAP]->{'DIRWATCH'} and defined $_[HEAP]->{'DIRWATCH'} ) {
		$_[HEAP]->{'DIRWATCH'}->shutdown;
		undef $_[HEAP]->{'DIRWATCH'};
	}

	# decrement the refcount
	if ( defined $_[HEAP]->{'SESSION'} ) {
		$_[KERNEL]->refcount_decrement( $_[HEAP]->{'SESSION'}, __PACKAGE__ );
	}

	$_[HEAP]->{'SHUTDOWN'} = 1;
	undef $_[HEAP]->{'WHEEL'};

	# remove the delay if needed
	$_[KERNEL]->alarm_remove( delete $_[HEAP]->{'_delay'} ) if exists $_[HEAP]->{'_delay'};

	return;
}

# received a postback from DirWatch
sub got_new_file : State {
	my $file = $_[ARG1]->[0]->stringify;

	# Have we seen this file before?
	if ( ! grep { $_ eq $file } @{ $_[HEAP]->{'NEWFILES'} } ) {
		if ( DEBUG ) {
			warn "Got a new file -> $file";
		}

		# Add it to the newfile list
		push( @{ $_[HEAP]->{'NEWFILES'} }, $file );

		# We're done!
		$_[KERNEL]->yield( 'send_report' );
	}

	return;
}

# We got a report directly from the POEGateway httpd!
sub http_report : State {
	my $report = $_[ARG0];

	if ( DEBUG ) {
		warn "Got a new report from POEGateway -> $report->{subject}";
	}

	# Shove it in the queue
	push( @{ $_[HEAP]->{'NEWFILES'} }, $report );
	$_[KERNEL]->yield( 'send_report' );
	return;
}

# Returns the length of the queue
sub queue : State {
	return scalar @{ $_[HEAP]->{'NEWFILES'} };
}

sub send_report_delayed : State {
	delete $_[HEAP]->{'_delay'} if exists $_[HEAP]->{'_delay'};
	$_[KERNEL]->yield( 'send_report' );
	return;
}

sub send_report : State {
	if ( ! defined $_[HEAP]->{'WHEEL'} ) {
		# Setup the subprocess!
		$_[KERNEL]->yield( 'setup_wheel' );
		return;
	}

	if ( $_[HEAP]->{'WHEEL_WORKING'} ) {
		return;
	}

	if ( exists $_[HEAP]->{'_delay'} ) {
		return;
	}

	# Grab the first file from the array
	my $file = $_[HEAP]->{'NEWFILES'}->[0];
	if ( ! defined $file ) {
		return;
	}

	# Is it a filename or hashref?
	my $data;
	if ( ! ref $file ) {
		# TODO Sometimes DirWatch gives us a new file notification *AFTER* we delete it... WTF???
		if ( ! -f $file ) {
			shift @{ $_[HEAP]->{'NEWFILES'} };
			return;
		}

		eval {
			$data = LoadFile( $file );
		};
		if ( $@ ) {
			if ( DEBUG ) {
				warn "Failed to load '$file': $@";
			}

			$_[KERNEL]->yield( 'save_failure', shift @{ $_[HEAP]->{'NEWFILES'} }, 'load' );
			return;
		} elsif ( ! defined $data ) {
			if ( DEBUG ) {
				warn "Malformed file: $file";
			}
			$_[KERNEL]->yield( 'save_failure', shift @{ $_[HEAP]->{'NEWFILES'} }, 'malformed' );
			return;
		}
	} else {
		$data = $file;
	}

	# do some housekeeping
	## no critic ( ProhibitAccessOfPrivateData )
	if ( exists $_[HEAP]->{'HOST_ALIASES'}->{ $data->{'_sender'} } ) {
		# do some regex tricks...
		$data->{'report'} =~ s/Environment\s+variables\:\n\n/Environment variables:\n\n    CPAN_SMOKER = $_[HEAP]->{'HOST_ALIASES'}->{ $data->{'_sender'} } ( $data->{'_sender'} )\n/;
		$data->{'_host'} = $_[HEAP]->{'HOST_ALIASES'}->{ $data->{'_sender'} };
	}

	# send it off to the subprocess!
	$data->{'_time'} = time;
	$_[HEAP]->{'WHEEL'}->put( {
		'ACTION'	=> 'SEND',
		'DATA'		=> $data,
	} );
	$_[HEAP]->{'WHEEL_WORKING'} = $data;

	return;
}

sub save_failure : State {
	my( $file, $reason ) = @_[ARG0, ARG1];

	# Get the filename only
	my $filename = ( File::Spec->splitpath( $file ) )[2];

	# Create the "fail" subdirectory if it doesn't exist
	my $faildir = File::Spec->catdir( $_[HEAP]->{'REPORTS'}, "fail" );
	if ( ! -d $faildir ) {
		mkdir( $faildir ) or die "Unable to mkdir '$faildir': $!";
	}

	# come up with a new name and move it
	$filename = File::Spec->catfile( $faildir, $filename . '.' . $reason );
	move( $file, $filename ) or die "Unable to move '$file': $!";

	# done with saving, let's retry the next report
	# do we need to delay between emails?
	if ( $_[HEAP]->{'DELAY'} > 0 ) {
		$_[HEAP]->{'_delay'} = $_[KERNEL]->delay_set( 'send_report_delayed' => $_[HEAP]->{'DELAY'} );
	} else {
		$_[KERNEL]->yield( 'send_report' );
	}

	return;
}

sub setup_wheel : State {
	# skip setup if we already have a wheel, eh?
	if ( defined $_[HEAP]->{'WHEEL'} ) {
		$_[KERNEL]->yield( 'send_report' );
		return;
	}

	# Check if we should set up the wheel
	if ( $_[HEAP]->{'WHEEL_RETRIES'} == 5 ) {
		die 'Tried ' . 5 . ' times to create a subprocess and is giving up...';
	}

	# Set up the SubProcess we communicate with
	my $pkg = __PACKAGE__ . '::' . $_[HEAP]->{'MAILER'};
	$_[HEAP]->{'WHEEL'} = POE::Wheel::Run->new(
		# What we will run in the separate process
		'Program'	=>	"$^X -M$pkg -e '${pkg}::main()'",

		# Kill off existing FD's
		'CloseOnCall'	=>	1,

		# Redirect errors to our error routine
		'ErrorEvent'	=>	'ChildError',

		# Send child died to our child routine
		'CloseEvent'	=>	'ChildClosed',

		# Send input from child
		'StdoutEvent'	=>	'Got_STDOUT',

		# Send input from child STDERR
		'StderrEvent'	=>	'Got_STDERR',

		# Set our filters
		'StdinFilter'	=>	POE::Filter::Reference->new(),		# Communicate with child via Storable::nfreeze
		'StdoutFilter'	=>	POE::Filter::Line->new(),		# Receive input via plain lines ( OK/NOK )
		'StderrFilter'	=>	POE::Filter::Line->new(),		# Plain ol' error lines
	);

	# Check for errors
	if ( ! defined $_[HEAP]->{'WHEEL'} ) {
		die 'Unable to create a new wheel!';
	} else {
		# smart CHLD handling
		if ( $_[KERNEL]->can( "sig_child" ) ) {
			$_[KERNEL]->sig_child( $_[HEAP]->{'WHEEL'}->PID => 'Got_CHLD' );
		} else {
			$_[KERNEL]->sig( 'CHLD', 'Got_CHLD' );
		}

		# Increment our retry count
		$_[HEAP]->{'WHEEL_RETRIES'}++;

		# it's obviously not working...
		$_[HEAP]->{'WHEEL_WORKING'} = 0;

		# Since we created a new wheel, we have to give it the config
		$_[HEAP]->{'WHEEL'}->put( {
			'ACTION'	=> 'CONFIG',
			'DATA'		=> $_[HEAP]->{'MAILER_CONF'},
		} );

		# Do we need to send something?
		$_[KERNEL]->yield( 'send_report' );
	}

	return;
}

# Handles child DIE'ing
sub ChildClosed : State {
	# Emit debugging information
	if ( DEBUG ) {
		warn "The subprocess died!";
	}

	# Get rid of the wheel
	undef $_[HEAP]->{'WHEEL'};

	# Should we process the next file?
	if ( scalar @{ $_[HEAP]->{'NEWFILES'} } and ! $_[HEAP]->{'SHUTDOWN'} ) {
		$_[KERNEL]->yield( 'wheel_setup' );
	}

	return;
}

# Handles child error
sub ChildError : State {
	# Emit warnings only if debug is on
	if ( DEBUG ) {
		# Copied from POE::Wheel::Run manpage
		my ( $operation, $errnum, $errstr ) = @_[ ARG0 .. ARG2 ];
		warn "Got an $operation error $errnum: $errstr\n";
	}

	return;
}

# Got a CHLD event!
sub Got_CHLD : State {
	$_[KERNEL]->sig_handled();
	return;
}

# Handles child STDERR output
sub Got_STDERR : State {
	my $input = $_[ARG0];

	# Skip empty lines as the POE::Filter::Line manpage says...
	if ( $input eq '' ) { return }

	warn "Got STDERR from child, which should never happen ( $input )";

	return;
}

# Handles child STDOUT output
sub Got_STDOUT : State {
	# The data!
	my $data = $_[ARG0];

	if ( DEBUG ) {
		warn "Got stdout ($data)";
	}

	# We should get: "OK $msgid" or "NOK $error"
	if ( $data =~ /^N?OK/ ) {
		my $file = shift( @{ $_[HEAP]->{'NEWFILES'} } );
		my $report = $_[HEAP]->{'WHEEL_WORKING'};
		$_[HEAP]->{'WHEEL_WORKING'} = 0;

		if ( $data =~ /^OK\s+(.+)\z/ ) {
			my $message_id = $1;

			if ( ! ref $file ) {
				if ( DEBUG ) {
					warn "Successfully sent report: $file";
				}

				# get rid of the file and move on!
				unlink( $file ) or die "Unable to delete $file: $!";
			} else {
				if ( DEBUG ) {
					warn "Successfully sent report: $file->{subject}";
				}
			}

			# do we need to delay between emails?
			if ( $_[HEAP]->{'DELAY'} > 0 ) {
				$_[HEAP]->{'_delay'} = $_[KERNEL]->delay_set( 'send_report_delayed' => $_[HEAP]->{'DELAY'} );
			} else {
				$_[KERNEL]->yield( 'send_report' );
			}

			if ( defined $_[HEAP]->{'MAILDONE'} and ref $report ) {
				$_[KERNEL]->post( $_[HEAP]->{'SESSION'} => $_[HEAP]->{'MAILDONE'}, {
					'STARTTIME'	=> delete $report->{'_time'},	## no critic ( ProhibitAccessOfPrivateData )
					'STOPTIME'	=> time,
					'DATA'		=> $report,
					'STATUS'	=> 1,
					'MSGID'		=> $message_id,
				} );
			}
		} elsif ( $data =~ /^NOK\s+(.+)\z/ ) {
			my $err = $1;

			# Is this a known error?
			#
			# This error happens with my postfix smtpd, because the link was left open too long between emails
			# Unable to send report for '/home/cpan/cpan_reports/1260750049.58c5ed3e0013517d0f168975795c2bba95f2be79': Unable to set 'from'
			# address: '4.4.2 mail.0ne.us Error: timeout exceeded' (421) at /usr/local/share/perl/5.10.0/Test/Reporter/POEGateway/Mailer.pm line 576.
			if ( $err =~ /timeout\s+exceeded/ ) {
				# Retry the email, but push it on the bottom of the queue!
				if ( DEBUG ) {
					warn "Received timeout for '$file', will give it another shot!";
				}

				push( @{ $_[HEAP]->{'NEWFILES'} }, $file );

				# do we need to delay between emails?
				if ( $_[HEAP]->{'DELAY'} > 0 ) {
					$_[HEAP]->{'_delay'} = $_[KERNEL]->delay_set( 'send_report_delayed' => $_[HEAP]->{'DELAY'} );
				} else {
					$_[KERNEL]->yield( 'send_report' );
				}

				return;
			}

			# argh!
			if ( ! ref $file ) {
				warn "Unable to send report for '$file': $err";
				$_[KERNEL]->yield( 'save_failure', $file, 'send' );
			} else {
				warn "Unable to send report for '$file->{subject}': $err";

				# do we need to delay between emails?
				if ( $_[HEAP]->{'DELAY'} > 0 ) {
					$_[HEAP]->{'_delay'} = $_[KERNEL]->delay_set( 'send_report_delayed' => $_[HEAP]->{'DELAY'} );
				} else {
					$_[KERNEL]->yield( 'send_report' );
				}
			}

			if ( defined $_[HEAP]->{'MAILDONE'} and ref $report ) {
				$_[KERNEL]->post( $_[HEAP]->{'SESSION'} => $_[HEAP]->{'MAILDONE'}, {
					'STARTTIME'	=> delete $report->{'_time'},	## no critic ( ProhibitAccessOfPrivateData )
					'STOPTIME'	=> time,
					'DATA'		=> $report,
					'STATUS'	=> 0,
					'ERROR'		=> $err,
				} );
			}
		} else {
			die "Malformed line: '$data'";
		}
	} elsif ( $data =~ /^ERROR\s+(.+)\z/ ) {
		# hmpf!
		my $err = $1;
		warn "Unexpected error: $err";
	} else {
		warn "Unknown line: '$data'";
	}

	return;
}

1;
__END__

=for stopwords TODO VM gentoo ip poegateway maildone emailer DirWatch ARG

=head1 NAME

Test::Reporter::POEGateway::Mailer - Sends reports via a configured mailer

=head1 SYNOPSIS

	#!/usr/bin/perl
	use strict; use warnings;
	use Test::Reporter::POEGateway::Mailer;

	# A sample using SMTP+SSL with AUTH
	Test::Reporter::POEGateway::Mailer->spawn(
		'mailer'	=> 'SMTP',
		'mailer_conf'	=> {
			'smtp_host'	=> 'smtp.mydomain.com',
			'smtp_opts'	=> {
				'Port'	=> '465',
				'Hello'	=> 'mydomain.com',
			},
			'ssl'		=> 1,
			'auth_user'	=> 'myuser',
			'auth_pass'	=> 'mypass',
		},
	);

	# run the kernel!
	POE::Kernel->run();

=head1 ABSTRACT

This module is the companion to L<Test::Reporter::POEGateway> and handles the task of actually mailing out reports. Typically you just
spawn the module, select a mailer and let it do it's work.

=head1 DESCRIPTION

Really, all you have to do is load the module and call it's spawn() method:

	use Test::Reporter::POEGateway::Mailer;
	Test::Reporter::POEGateway::Mailer->spawn( ... );

This method will return failure on errors or return success. Normally you would select the mailer and set various options.

This constructor accepts either a hashref or a hash, valid options are:

=head3 alias

This sets the alias of the session.

The default is: POEGateway-Mailer

=head3 mailer

This sets the mailer subclass. The only one bundled with this distribution is L<Test::Reporter::POEGateway::Mailer::SMTP>.

NOTE: This module automatically prepends "Test::Reporter::POEGateway::Mailer::" to the string.

The default is: SMTP

=head3 mailer_conf

This sets the configuration for the selected mailer. Please look at the POD for your selected mailer for what options is accepted.

NOTE: This needs to be a hashref!

The default is: {}

=head3 delay

This sets the delay in seconds between email sends. This is useful to "throttle" your emailer. Set to 0 to disable any delay.

The default is: 0

=head3 poegateway

If this option is present in the arguments, this module will receive reports directly from the L<Test::Reporter::POEGateway> session. You cannot
enable this option and use the reports argument below at the same time. If you enable this, this component will not use L<POE::Component::DirWatch>
and ignores any options for it.

The default is: undef ( not used )

	use Test::Reporter::POEGateway;
	use Test::Reporter::POEGateway::Mailer;

	Test::Reporter::POEGateway->spawn(
		'mailer'	=> 'mymailer',
	);
	Test::Reporter::POEGateway::Mailer->spawn(
		'alias'		=> 'mymailer',
		'poegateway'	=> 1,
		'mailer'	=> 'SMTP',
		'mailer_conf'	=> { ... },
	);

=head3 reports

This sets the path where it will read received report submissions. Should be the same path you set in L<Test::Reporter::POEGateway>.

NOTE: If this module fails to send a report due to various reasons, it will move the file to '$reports/fail' to avoid re-sending it over and over.

The default is: $ENV{HOME}/cpan_reports

=head3 dirwatch_alias

This sets the alias of the L<POE::Component::DirWatch> session. Normally you don't need to touch the DirWatch session, but it is useful in certain
situations. For example, if you wanted to pause the watcher or re-configure - all you need to do is to send events to this alias.

The default is: POEGateway-Mailer-DirWatch

=head3 dirwatch_interval

This sets the interval in seconds passed to L<POE::Component::DirWatch>, please see the pod for more detail.

The default is: 120

=head3 host_aliases

This is a value-added change from L<Test::Reporter::HTTPGateway>. This sets up a hash of ip => description. When the mailer sends a report, it
will munge the report by adding a "fake" environment variable: SMOKER_HOST and put the description there if the sender ip matches. This is extremely
useful if you have multiple smokers running and want to keep track of which smoker sent which report.

Here's a sample alias list:
	host_aliases => {
		'192.168.0.2' => 'my laptop',
		'192.168.0.5' => 'my smoke box',
		'192.168.0.7' => 'gentoo VM on smoke box',
	},

The default is: {}

=head3 maildone

This sets the event which will receive notifications when an email is sent or not. Receives one data structure in ARG0:

	{
		'STARTTIME'	=> 1260432932,					# self-explanatory
		'STOPTIME'	=> 1260432965,					# self-explanatory

		'STATUS'	=> 1,						# boolean value for success
		'MSGID'		=> '1260563289.Ca1bb50.15987@smoker-master',	# will exist if status == 1
		'ERROR'		=> 'SMTP AUTH failed',				# will exist if status == 0

		'DATA'		=> {						# The report's data
			'report'	=> 'TEXT OF REPORT',
			'subject'	=> 'PASS Acme-LOLCAT-0.0.5 x86_64-linux 2.6.31-14-server',
			'from'		=> 'apocal@cpan.org',
			'via'		=> 'Test::Reporter 1.54, via CPANPLUS 0.88, via Test::Reporter::POEGateway 0.01',
			'_sender'	=> '192.168.0.2',

			'_host'		=> 'my laptop',				# will exist if _sender matched a host alias
		},
	}

The default is: undef ( not enabled )

=head3 session

This sets the session which will receive the notification event. You can either use a POE session id, alias, or reference. You can just spawn the component
inside another session and it will automatically receive the notifications.

The default is: undef ( caller session )

=head2 Commands

There is only a few command you can use, as this is a very simple module.

=head3 queue

Receives the email queue count. You need to call this via $poe_kernel->call( ... ) !

	my $count = $_[KERNEL]->call( 'POEGateway-Mailer', 'queue' );
	print "Number of pending emails in the queue: $count\n";

=head3 shutdown

Tells this module to shut down the underlying httpd session and terminate itself.

	$_[KERNEL]->post( 'POEGateway-Mailer', 'shutdown' );

=head2 More Ideas

Additional mailers ( sendmail ), that's for sure. However, L<Test::Reporter::POEGateway::Mailer::SMTP> fits the bill for me; I'm lazy now :)

=head1 EXPORT

None.

=head1 SEE ALSO

L<Test::Reporter::POEGateway>

L<Test::Reporter::POEGateway::Mailer::SMTP>

=head1 AUTHOR

Apocalypse E<lt>apocal@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 by Apocalypse

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
