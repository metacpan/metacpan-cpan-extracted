package BBPerl;
use warnings;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter);
$VERSION = sprintf "%d.%03d", q$Revision: 1.55 $ =~ /: (\d+)\.(\d+)/;

use Net::Domain;

sub new {
	my $class = shift;
	my $tname = shift;
	my $self =
	{
		_debug => 0,
		_testName => "My_Test",
		_status => "green",
		_bbmsgs => "",
		_bbhome => $ENV{BBHOME},
		_bbtmp => $ENV{BBTMP},
		_bbcmd => $ENV{BB},
		_bbdisp => $ENV{BBDISP},
		_msgsnum=> 0,
		_hostname => Net::Domain->hostname(),
		_usefqdn=>0
	};

	if ($tname) {
		$tname =~ s/ /_/g;
		$self->{_testName} = $tname;
	}
	die "BBHOME is not set.... Exiting\n" if ! $ENV{BBHOME};
	die "BBTMP is not set... Make sure to run \". \$BBHOME/etc/bbdef.sh\"\n" if ! $ENV{BBTMP};
	bless $self,$class;
	return $self;
}

sub useFQDN {
	my $self = shift;
	if (@_) {
		$self->{_usefqdn} = shift;
		if ($self->{_usefqdn}) {
			$self->{_hostname} = Net::Domain->hostfqdn();
		} else {
			$self->{_hostname} = Net::Domain->hostname();
		}
	}
	return $self->{_usefqdn};
}


sub debugLevel {
	my $self=shift;
	if (@_)
	{
		$self->{_debug} = shift;
	}
	return $self->{_debug};
}

sub testName {
	my ($self,$tname) = @_;
	if ($tname)
	{
		$tname =~ s/ /_/g;
		$self->{_testName} = $tname;
	}
	return $self->{_testName};
}

sub status {
	my $self = shift;
	if (@_)
	{
		my $stat=shift;
		$stat =~ tr/A-Z/a-z/;
		$self->{_status} = $stat if $stat =~ /red|yellow|green|purple|blue/;
	}
	return $self->{_status};
}

sub addMsg {
	my ($self,$msg) = @_;
	return $self->{_bbmsgs} if $self->{_msgsnum} >= 75;
	$self->{_bbmsgs} .= "\n".$msg if defined($msg);
	$self->{_msgsnum}++;
	return $self->{_bbmsgs};
}

sub getMsgCount {
	my $self = shift;
	return $self->{_msgsnum};
}

sub bbdisp {
	my $self = shift;
	if (@_) {
		$self->{_bbdisp} = shift;
	}
	return $self->{_bbdisp};
}

# Deprecated beyond 1.3
sub localhost {
	my $self = shift;
	if (@_) {
		$self->hostname(shift);
	}
	return $self->hostname();
}

sub hostname {
	my $self = shift;
	if (@_) {
		$self->{_hostname} = shift;
		$self->{_usefqdn} = 0;
	}
	return $self->{_hostname};
}

sub bbhome {
	my $self = shift;
	if (@_) {
		$self->{_bbhome} = shift;
	}
	return $self->{_bbhome};
}

sub bbcmd {
	my $self = shift;
	if (@_) {
		$self->{_bbcmd} = shift;
	}
	return $self->{_bbcmd};
}

sub bbtmp {
	my $self = shift;
	if (@_) {
		$self->{_bbtmp} = shift;
	}
	return $self->{_bbtmp};
}




sub send {
	sub _date() {
		use POSIX qw(strftime);
		my @monstr = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
		my @daystr = qw(Sun Mon Tue Wed Thr Fri Sat);

		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
		my $year_long = 1900 + $year;
		my $tz = strftime('%Z', localtime);

		return sprintf '%3s %3s %2s %02s:%02s:%02s %3s %4s', $daystr[$wday], $monstr[$mon], $mday, $hour, $min, $sec, $tz, $year_long;
	}
	my $self = shift;
	my $debug = $self->{_debug};
	my $cmdline = $self->{_bbcmd}." ".$self->{_bbdisp};
	my $localhostname = $self->{_hostname};
	$localhostname =~ s/\./,/g;
	my $statusline = "status ".$localhostname.".".$self->{_testName}." ".$self->{_status}." "._date();
	chomp ($statusline);
	if ($debug > 0) {
		print "The following will be sent using command:\n";
		print $cmdline;
		print "\n---------------------------------------------------------\n";
		print $statusline;
		print $self->{_bbmsgs};
		print "---------------------------------------------------------\n";
	}
	if ($debug < 2) {
		my $bbmsgs=$self->{_bbmsgs};
		$bbmsgs =~ s/"/\\"/g;
# Like this would ever work.
#		open (BBPIPE,"| ${cmdline} -") or die "Cannot open STDOUT to report\n";
#		print BBPIPE "$statusline $bbmsgs";
#		print BBPIPE $self->{_bbmsgs};
#		close (BBPIPE);
#		system("$self->{_bbhome}/bin/bb-combo.sh","add","\"$statusline\n$bbmsgs\n\"");
		my $bsvar=`${cmdline} "${statusline}
${bbmsgs}
"`;
	} else {
		print "Debug level $debug prevents me from sending to the Big Brother Server.\n";
	}
}

1;

__END__

=pod

=head1 NAME

BBPerl - Perl module for the ease of writing Perl based big brother monitors.

=head1 SYNOPSIS

use BBPerl;

$bbmonitor = new BBPerl ('My_Monitor');

$bbmonitor->debugLevel(1);

$bbmonitor->testName('My_Monitor');

$bbmonitor->status('red');

$bbmonitor->addMsg('Something is very wrong');

$bbmonitor->send;

=head1 DESCRIPTION

This module is designed to ease the ability to send Big Brother style
monitor messages.

It will check to make sure it is running with a proper environment by 
making sure the environment variables BBHOME and BBTMP are set. If they
are not, it will cause the program to abort with a message explaining
the reason for the failure.

=head2 Methods

=over 4

=item * $bbmonitor->debugLevel()

When called with a parameter, this sets the debug level. When no argument
is used, returns the debug level.

=item * $bbmonitor->testName("My_Test")

When called with a parameter, this sets the name of the test, or otherwise known
as the column name under which to report the results of the monitor test. When no
arguement is used, it returns the name of the test.

=item * $bbmonitor->status("red")

While anything can be set here, the only valid stati for Big Brother are 
(green, yellow, red, purple). When called with a parameter, this sets the 
status of the report. When no arguement is used, it returns the current status.

=item * $bbmonitor->addMsg("I have something else to report")

Adds more information to the report sent back to the Big Brother server. Each
time this is called, the message is appended with an automatic line feed. 
Currently, this reporting tool only allows up to 75 lines to be reported. Most
BB servers only allow 50 lines, then show a DATA TRUNCATED message.

=item * $bbmonitor->getMsgCount()

This will return the number of lines that are in the current message buffer.
This can be useful to see if during a long report, you are coming close to the
maximum number of lines that BB is allowed to accept. 

=item * $bbmonitor->bbdisp

This method will tell you what the BB Display server is set to, or if you 
call it with a parameter, it will override what the current BB environment
has set for the Big Brother Pager.

=item * $bbmonitor->hostname

This method will tell you what will be reported to the Big Brother server as 
the originating host name. If you set this, it will report to big brother as
if it were coming from the host name specified. If you set this value, it will
set the useFQDN to 0.

=item * $bbmonitor->useFQDN()

This method will instruct the BB monitor to report the full FQDN of the host.
If set to 1, the domain name of the host will be included in the report. If
set to 0, only the hostname will be reported to the BB server. Setting this
value will override the hostname set using the $bbmonitor->hostname function
and set it either to the hostname or the hostfqdn. Checking this value will
let you know if the monitor will report the FQDN.

=item * $bbmonitor->bbhome

This method will tell you what the BBHOME environment variable is set to. 
You can change this by passing a parameter with a new path, but this is
HIGHLY not recommended.

=item * $bbmonitor->bbcmd

This method will tell you the full path to the big brother client executable.
You can change this by passing a parameter with a new path. I saw no need for 
this, however in the spirit of flexibility, I put this in here.

=item * $bbmonitor->bbtmp

This method will tell you the full path to Big Brother temp directory. You can
change the temp directory by setting this parameter, however it is highly
discouraged.

=item * $bbmonitor->send

This method should be called last to send the message to the Big Brother server. 

=back

=head1 AUTHOR

Eirik Toft (grep_boy@yahoo.com) with thanks to Kenneth T Dreyer who created 
more platform independancy in the code.

=cut
