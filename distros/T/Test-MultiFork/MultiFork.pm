
package Test::MultiFork;

use Filter::Util::Call ;
use Event;
use IO::Event;
use IO::Handle;
use Storable qw(freeze thaw);
require POSIX;
use Socket;
require Exporter;
use Time::HiRes qw(sleep);
use Carp;

#print STDERR "IOE V: $IO::Event::VERSION\n";

$VERSION = 0.6;

@ISA = qw(Exporter);
@EXPORT = qw(procname lockcommon unlockcommon getcommon setcommon);
@EXPORT_OK = (@EXPORT, qw(groupwait setgroup dofork));

use strict;
use warnings;

# server side
my $stderr;
my $colorize;
my %capture;
my %control;
my $sequence = 1;
my $commonlock;	# current holder of lock
my @commonwait;	# waiting for lock
my $common = freeze([]);
my %groups;
my $timer;
my $bialout;
my $ret = '';
my $bailonbadplan = 0;

our $inactivity; 
$inactivity ||= 5;

# client side
my $server;
my $newstdout;
my $letter;
my $number;
my $name;
my $lockdepth = 0;
my $group = 'default';
my $waiting;

# debugging

our $debug_common = 0;
our $debug_groupwait = 0;

# constants

my $pkg = __PACKAGE__;
my %color = (
	black	=> 0,
	red	=> 1,
	green	=> 2,
	yellow	=> 3,
	blue	=> 4,
	magenta	=> 5,
	cyan	=> 6,
	white	=> 7,
	default	=> 9,
);
my %color_bg = (
	a	=> $color{black},
	b	=> $color{blue},
	c	=> $color{green},
	d	=> $color{red},
	e	=> $color{cyan},
	f	=> $color{magenta},
	g	=> $color{yellow},
);
my @color_fg = (
	'notused',
	$color{white},
	$color{yellow},
	$color{cyan},
	$color{magenta},
	$color{red},
	$color{green},
	$color{blue},
	$color{black},
);

# shared
my $signal;

sub import 
{
	my $pkg = shift;
	my @ia;
	for my $ia (@_) {
		if ($ia eq 'stderr') {
			$stderr = 1;
		} elsif ($ia eq 'colorize') {
			$colorize = ($ENV{TERM} =~ /xterm/) && ! $ENV{HARNESS_ACTIVE};
		} elsif ($ia eq 'bail_on_bad_plan') {
			$bailonbadplan = 1;
		} else {
			push(@ia, @_);
		}
	}
	filter_add(bless [], $pkg);
	$pkg->export_to_level(1, @ia);
}

sub dofork
{
	my ($spec) = @_;

	while($spec) {
		$spec =~ s/^([a-z])(\d*)// || confess "illegal fork spec";
		my $l = $1;
		my $count = $2 || 1;
		for my $n (1..$count) {
			my $pid;
			my $psideCapture = new IO::Handle;
			my $psideControl = new IO::Handle;
			$server = new IO::Handle;
			$newstdout = new IO::Handle;
			socketpair($psideCapture, $newstdout, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
				|| confess "socketpair: $!";
			socketpair($psideControl, $server, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
				|| confess "socketpair: $!";
			if ($pid = fork()) {
				# parent
#sleep(0.1);
				$server->close();
				$newstdout->close();

				if (0 && 'CRAZY_STUFF') { 
					use IO::Pipe;
					my $pipe = new IO::Pipe;

					if (fork()) {
						$newstdout->close();
						$pipe->reader();
						$psideCapture = $pipe;
					} else {
						$pipe->writer();
						my $fn = $pipe->fileno();
						open(STDOUT, ">&=$fn") || confess "redirect stdout2: $!";
						$fn = $psideCapture->fileno();
						open(STDIN, "<&=", $fn) || confess "redirect stdin: $!";
						exec("tee bar.$$") || confess "exec: $!";
					}
				}

				Test::MultiFork::Control->new($psideControl, $l, $n, $pid);
				Test::MultiFork::Capture->new($psideCapture, $l, $n);

			} elsif (defined $pid) {
				# child
				$letter = $l;
				$number = $n;
				$name = "$l-$n";

				$psideCapture->close();
				$psideControl->close();
				for my $c (keys %capture) {
					$capture{$c}{ie}->close();
					delete $capture{$c};
				}
				for my $c (keys %control) {
					$control{$c}{ie}->close();
					delete $control{$c};
				}

				if (0 && 'CRAZY_STUFF') { 
					use IO::Pipe;
					my $pipe = new IO::Pipe;

					if (fork()) {
						$newstdout->close();
						$pipe->writer();
						$newstdout = $pipe;
					} else {
						my $fn = $newstdout->fileno();
						open(STDOUT, ">&=$fn") || confess "redirect stdout2: $!";
						$pipe->reader();
						$fn = $pipe->fileno();
						#close(STDIN);
						open(STDIN, "<&=", $fn) || confess "redirect stdin: $!";
						exec("tee foo.$$") || confess "exec: $!";
					}
				}

				$newstdout->autoflush(1);
				$server->autoflush(1);
				if (defined &Test::Builder::new) {
					my $tb = new Test::Builder;
					$tb->output($newstdout);
					$tb->todo_output($newstdout);
					$tb->failure_output($newstdout);
				}
				my $fn = $newstdout->fileno();
				open(STDOUT, ">&=$fn") || confess "redirect stdout: $!";
				autoflush STDOUT 1;
				if ($stderr) {
					open(STDERR, ">&=$fn") || confess "redirect stdout: $!";
					autoflush STDERR 1;
				}
				
				$SIG{$signal} = \&lastrites
					if $signal;

				$waiting = "for initial begin";
				my $x = <$server>;
				confess unless $x eq "begin\n";
				undef $waiting;

				return;
			} else {
				confess "Can't fork: $!";
			}
		}
	}
#print "about to create timer\n";
	$timer = Test::MultiFork::Timer->new();

#print "sending begin\n";
	for my $control (values %control) {
		$control->{fh}->print("begin\n");
	}

	# exit on die
	$Event::DIED = sub {
		Event::verbose_exception_handler(@_);
		Event::unloop_all();
	};

#print "event loop\n";
	if (Event::loop() == 7.3) {
		# great
		notokay(0, '', '', '', "clean shutdown");
	} else {
		notokay(1, '', '', '', "event loop timeout");
	}
	$sequence--;
	print "\n1..$sequence\n";
	exit(0);
}

sub groupwait
{
	my ($tag) = @_;
	my (undef, $filename, $line) = caller;
	$tag = "$filename:$line" unless $tag;
	print $server "waitforgroup $tag\n";
	$waiting = "for go-ahead after a group wait ($group)";
	my $go = <$server>;
	confess "go='$go' (not 'go\\n')" unless $go eq "go\n";
	undef $waiting;
}

sub procname
{
	my $oname = $name;
	if (@_) {
		$name = $_[0];
		confess if $name =~ /\n/;
		print $server "setname $name\n";
	}
	return ($name, $letter, $number) if wantarray;
	return $name;
}

sub setgroup
{
	my $og = $group;
	if (@_) {
		$group = $_[0];
		confess if $group =~ /\n/;
		print $server "setgroup $group\n";
	}
	return $og;
}

sub lockcommon
{
	print STDERR "\n[$letter-$number] locking common -request\n" if $debug_common;
	unless ($lockdepth++) {
		print $server "lock common\n";
		$waiting = "lock on common data";
		my $youhavelock = <$server>;
		confess unless $youhavelock eq "youhavelock\n";
		undef $waiting;
	}
	print STDERR "\n[$letter-$number] locking common done\n" if $debug_common;
}

sub unlockcommon
{
	print STDERR "\n[$letter-$number] unlocking common -request\n" if $debug_common;
	unless (--$lockdepth) {
		print $server "unlock common\n";
		undef $common;
	}
	if ($lockdepth < 0) {
		warn "common already unlocked";
		$lockdepth = 0;
	}
	print STDERR "\n[$letter-$number] unlocking common done\n" if $debug_common;
}

sub getcommon 
{
	print STDERR "\n[$letter-$number] get common - request\n" if $debug_common;
	print $server "get common\n";
	$waiting = "to get size of common data";
	my $size = <$server>;
	$waiting = "for common data";
	my $buf;
	my $amt = read($server, $buf, $size);
	confess unless $amt == $size;
	undef $waiting;
	my $r = thaw($buf);
	print STDERR "\n[$letter-$number] get common done\n" if $debug_common;
	return @$r if wantarray;
	return $r->[0];
}

sub setcommon 
{
	print STDERR "\n[$letter-$number] set common -request\n" if $debug_common;
	my $x = freeze([@_]);
	print $server "set common\n";
	print $server length($x)."\n";
	print $server $x;
	print STDERR "\n[$letter-$number] set common done\n" if $debug_common;
}

sub notokay
{
	my ($not, $name, $letter, $n, $comment) = @_;
	$not = $not ? "not " : "";
	$name = " - $name" unless $name =~ /^\s*-/;
	$comment = "" unless defined $comment;
	cprint($letter, $n, "${not}ok $sequence $name # $comment\n");
	$sequence++;
}

sub lastrites
{
	if ($waiting) {
		print STDERR "\nSERVER WAIT $name $number-$letter: $waiting";
	}
	confess;
}

sub cprint
{
	my $letter = shift;
	my $n = shift;
	if ($colorize && $letter) {
		my $fg = $color_fg[$n] || 7;
		my $bg = $color_bg{$letter} || 0;
		$fg = 7 if $bg == $fg;
		print "\x9b3${fg}m\x9b4${bg}m";
		print @_;
		print "\x9b39m\x9b49m";
	} else {
		print @_;
	}
}

sub filter {
	my ($self) = @_;

	my @new;
	while (filter_read() > 0) {
		push(@new, $_);
		$_ = '';
	}
	if (@new) {
		my %procs;
		my $insub = '';
		my $active = 1;
		my $fork;

		for (@new) {
			if (s/^(FORK_([a-z0-9]+):\s*)$/## $1/) {
				confess "only one FORK_ allowed" if $fork;
				$fork = $2;
			} elsif (s/^(SIGNAL_(\w*):\s*)$/## $1/) {
				confess "only one SIGNAL_ allowed" if defined $signal;
				$signal = $2;
			}
		}
		$signal = 'USR1' unless defined $signal;
		$signal = '' if $signal eq 'none';
			
		if (defined $fork) {
			dofork($fork);

			while (@new) {
				$_ = shift @new;

				if (/^sub\s+\w+(?!.*?;)/) {
					$insub = 1; # {
				} elsif (/^}/) {
					$insub = 0;
				}

				if (/^([a-z]+):/) {
					my $sets = $1;
					$active = (($sets =~ /$letter/o) ? 1 : 0);
					unless ($insub) {
						push(@$self, "${pkg}::groupwait();\n")
					} else {
						push(@$self, "#$insub# $_");
					}
				} elsif ($active) {
					push(@$self, $_);
				} else {
					push(@$self, "#$insub# $_");
				}
			}
		} else {
			# no builtin fork
			@$self = @new;
		}
#print "SOURCE: @$self\n DONE\n";
	}
	return 0 unless @$self;
	$_ = shift @$self;
	return 1;
}

package Test::MultiFork::Timer;

use Carp;
use strict;
use warnings;

sub new
{
	my ($pkg) = @_;
	my $self = bless { }, $pkg;

	$self->{event} = Event->timer(
		cb		=> [ $self, 'timeout' ],
		interval	=> $inactivity,
		hard		=> 0,
	);
	return $self;
}

sub timeout
{
	print STDERR "\nBail out!  Timeout in Test::MultiFork\n";

	for my $c (values %control) {
		my $x = ($c->{name} eq $c->{code}) ? $c->{name} : "$c->{name} ($c->{code})";
		my $y = $c->{status} 
			? $c->{status} 
			: ($c->{waiting} 
				? "waiting for $c->{group} for $c->{waiting}"
				: ($c->{lockstatus}
					? $c->{lockstatus}
					: "idle"));
		my @z;
		my $e = $c->{ie}->event;
		push(@z, "cancelled") if $e->is_cancelled;
		push(@z, "active") if $e->is_active;
		push(@z, "running") if $e->is_running;
		push(@z, "suspended") if $e->is_suspended;
		push(@z, "pending") if $e->pending;
		print STDERR "$x: $y (event status: @z)\n";
		if ($signal) {
			kill($signal, $c->{pid});
		}
		sleep(0.2);
	}
	Event::unloop_all(7.2) unless %control || %capture;
	exit(1);
}

sub reset
{
	my ($self) = @_;
#my (undef, $f, $l) = caller;
#print "timer reset from $f:$l\n";
	$self->{event}->stop();
	$self->{event}->again();
}

package Test::MultiFork::Capture;

use Carp;
use strict;
use warnings;

sub new
{
	my ($pkg, $fh, $letter, $n) = @_;
	my $self = bless {
		letter	=> $letter,
		n	=> $n,
		seq	=> 1,
		plan	=> undef,
		code	=> "$letter-$n",
		name	=> "$letter-$n",
	}, $pkg;
	$self->{ie} = IO::Event->new($fh, $self);
	$capture{$self->{code}} = $self;
	return $self;
}

sub ie_input
{
	my ($self, $ie) = @_;
	$timer->reset;
	my $bailout;
	while (<$ie>) {
# print "\nRECV$self->{n}: '$_'";
		chomp;
		if (/^(?:(not)\s+)?ok\S*(?:\s+(\d+))?([^#]*)(?:#(.*))?$/) {
			my ($not, $seq, $name, $comment) = ($1, $2, $3, $4);
			$name = '' unless defined $name;
			$comment = '' unless defined $name;
			if (defined($seq)) {
				if ($seq != $self->{seq}) {
					Test::MultiFork::notokay(1, $self->{name}, $self->{letter}, $self->{n},
						"result ordering in $self->{name}", 
						"expected '$self->{seq}' but got '$seq'");
				}
				$self->{seq} = $seq+1;
			} else {
				$self->{seq}++;
			}
			$comment .= " [ $self->{name} #$seq ]";
			Test::MultiFork::notokay($not, $name, $self->{letter}, $self->{n}, $comment);
			next;
		}
		if (/^1\.\.(\d+)/) {
			Test::MultiFork::notokay(1, $self->{name}, $self->{letter}, $self->{n}, "multiple plans")
				if defined $self->{plan};
			$self->{plan} = $1;
			next;
		}
		Test::MultiFork::cprint($self->{letter}, $self->{n}, "$_ [$self->{name}]\n");
	}
	exit 1 if $bailout;
}

sub ie_eof
{
	my ($self, $ie) = @_;
	if ($self->{plan}) {
		$self->{seq}--;
		if ($self->{plan} == $self->{seq}) {
			Test::MultiFork::notokay(0, $self->{name}, $self->{letter}, $self->{n}, "plan followed");
		} else {
			Test::MultiFork::notokay(1, $self->{name}, $self->{letter}, $self->{n},  
				"plan followed $self->{seq}",
				"plan: $self->{plan} actual: $self->{seq}");
		}
	} 
	$ie->close();
	delete $capture{$self->{code}};
	Event::unloop_all(7.3) unless %control || %capture;
}


package Test::MultiFork::Control;

use Carp;
use strict;
use warnings;

sub new
{
	my ($pkg, $fh, $letter, $n, $pid) = @_;
	my $self = bless {
		fh	=> $fh,
		letter	=> $letter,
		n	=> $n,
		seq	=> 1,
		plan	=> undef,
		code	=> "$letter-$n",
		name	=> "$letter-$n",
		group	=> 'default',
		pid	=> $pid,
		# waiting
	}, $pkg;
	$self->{ie} = IO::Event->new($fh, $self);
	$control{$self->{code}} = $self;
	$groups{default}{"$letter-$n"} = $self;
	return $self;
}

sub ie_input
{
	my ($self, $ie) = @_;
#print "\nBEGIN ie_input for $self->{code}";
#print "\ncontrol input...";
	$timer->reset;
	while (<$ie>) {
#my $x = $_;
#$x =~ s/\n/\\n/g;
#print "\nCONTROL: $self->{code}:$x.";

		### name

		if (/^setname (.*)/) {
			$self->{name} = $1;
			$capture{$self->{code}}{name} = $1
				if exists $capture{$self->{code}};

		### common (shared data)

		} elsif (/^lock common/) {
			if ($commonlock) {
				push(@commonwait, $self);
				$self->{status} = "waiting for common data lock";
			} else {
				$commonlock = $self;
				$self->{lockstatus} = "holding common data lock";
#print "\nSEND TO $self->{code}: youhavelock\n";
				print $ie "youhavelock\n";
			}
		} elsif (/^unlock common/) {
			confess unless $commonlock eq $self;
			delete $self->{lockstatus};
			$commonlock = shift @commonwait;
			if ($commonlock) {
#print "\nWAKEUP SEND TO $commonlock->{code}: youhavelock\n";
				$commonlock->{fh}->print("youhavelock\n");
				$commonlock->{lockstatus} = "holding common data lock";
				delete $commonlock->{status};
			}
		} elsif (/^set common/) {
			confess unless $commonlock eq $self;
			my $size = $ie->get();
			if (defined $size) {
				if ($ie->can_read($size)) {
					read($ie, $common, $size) == $size
						|| confess;
				} else {
					$ie->unget($size);
					$ie->unget("set common");
					$self->{status} = "waiting for common data";
					last;
				}
			} else {
				$ie->unget("set common");
				$self->{status} = "waiting for size of common data";
				last;
			}
		} elsif (/^get common/) {
#print "\nSEND TO $self->{code}: length & common";
			print $ie length($common)."\n";
			print $ie $common;

		### group afiliation

		} elsif (/^setgroup (.*)/) {
			$self->{newgroup} = $1;
		
		### synchronization

		} elsif (/^waitforgroup (.*)/) {
			$self->{waiting} = $1;
			wake_group($self->{group});
		### oops

		} else {
			confess "unknown control: $_";
		}
	}
#print "\nstatus = $self->{status}";
#print "\nEND ie_input for $self->{code}\n";
#print "return\n";
}

sub ie_eof
{
	my ($self, $ie) = @_;
	$ie->close();
	delete $control{$self->{code}};
	Event::unloop_all(7.3) unless %control || %capture;
}

sub wake_group
{
	my ($group) = @_;
	my $allthere = 1;
	my @members = values %{$groups{$group}};
	my $tag;
	for my $member (@members) {
		if ($member->{waiting}) {
			print "$member->{code} waiting at $member->{waiting}\n" if $debug_groupwait;
			if (defined $tag) {
				if ($tag ne $member->{waiting}) {
					Test::MultiFork::notokay(1, 
						$members[0]->{name}, 
						$members[0]->{letter}, 
						$members[0]->{n},
						sprintf("inconsistent group wait locations: %s:'%s' vs %s:'%s'", 
							$members[0]->{name},
							$members[0]->{waiting},
							$member->{name},
							$member->{waiting}));
				}
			} else {
				$tag = $member->{waiting}
			}
		} else {
			print "$member->{code} not waiting\n" if $debug_groupwait;
			$allthere = 0;
			last;
		}
	}
	if ($allthere) {
		print "ALL THERE\n" if $debug_groupwait;
		for my $member (@members) {
			next unless $member->{newgroup};
			delete $groups{$member->{group}}{$member->{code}};
			$member->{group} = $1;
			$groups{$member->{newgroup}}{$member->{code}} = $member;
			delete $member->{newgroup};
		}
		for my $member (@members) {
			delete $member->{waiting};
			print "WAKEUP $member->{code}\n" if $debug_groupwait;
			$member->{fh}->print("go\n");
		}
	}
}

1;
