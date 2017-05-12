package Test::Tarantool;

use 5.006;
use strict;
use warnings;
use IO::Handle qw/autoflush/;
use Scalar::Util 'weaken';
use AnyEvent::Handle;
use Data::Dumper;

=head1 NAME

Test::Tarantool - The Swiss army knife for tests of Tarantool related Perl and lua code.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';
our $Count = 0;
our %Schedule;

=head1 SYNOPSIS

    use Test::Tarantool;
    use AnyEvent;

    # Clear data and exit on Ctrl+C.
    my $w = AnyEvent->signal (signal => "INT", cb => sub { exit 0 });

    my @shards = map {
        my $n = $_;
        Test::Tarantool->new(
            host => '127.17.3.0',
            spaces => 'space[0] = {
                           enabled = 1,
                           index = [ {
                               type = HASH,
                               unique = 1,
                               key_field = [ { fieldno = 0, type = STR }, ],
                           }, ],
                       }',
            initlua => do {
                          open my $f, '<', 'init.lua';
                          local $/ = undef;
                          <$f> or "";
                       },
            on_die => sub { warn "Shard #$n unexpectedly terminated\n"; exit; },
        );
    } 1..4;

    my @cluster = map { [ $_->{host}, $_->{p_port} ] } @shards;

    {
        my $cv = AE::cv();
        $cv->begin for (@shards);
        $_->start($cv) for (@shards);
        $cv->recv;
    }

    {
        $_->sync_start() for (@shards);
    }

    {
        my ($status, $reason) = $shards[0]->sync_ro();
        die $reason unless $status;
        print (($shards[0]->sync_admin_cmd("show info"))[1]);
    }

    # Some test case here

    $shards[1]->pause();

    # Some test case here

    $shards[1]->resume();

    {
        my ($status, $reason) = $shards[0]->sync_rw();
        die $reason unless $status;
        print (($shards[0]->sync_admin_cmd("show info"))[1]);
    }

    # stop tarantools and clear work directoies
    @shards = ();

=head1 SUBROUTINES/METHODS

=head2 new option => value,...

Create new Tarantool instance. Every call of new method increase counter, below
called as I<tarantool number> or I<tn>.

=over 4

=item root => $path

Tarantool work directory. Default is I<./tnt_E<lt>10_random_lowercase_lettersE<gt>>

=item arena => $size

The maximal size of tarantool arena in Gb. Default is I<0.1>

=item cleanup => $bool

Remove tarantool work directory after garbage collection. Default is I<1>

=item spaces => $string

Tarantool spaces description. This is only one B<required> argument.

=item initlua => $content

Content of init.lua file. Be default an empty file created.

=item host => $address

Address bind to. Default: I<127.0.0.1>

=item port => $port

Primary port number, base for s_port, a_port and r_port. Default is I<6603+E<lt>tnE<gt>*4>

=item s_port => $port

Read-only (secondary) port. Default is I<port+1>

=item a_port => $port

Admin port. Default is I<port+2>

=item r_port => $port

Replication port. Default is I<port+3>

=item title => $title

Part of process name (custom_proc_title) Default is I<"yatE<lt>tnE<lt>">

=item wal_mode => $mode

The WAL write mode. See the desctiption of wal_mode tarantool variable. Default
is I<none>. Look more about wal_mode in tarantool documentation.

=item log_level => $number

Tarantool log level. Default is I<5>

=item snapshot => $path

Path to some snapshot. If given the symbolic link to it will been created in
tarantool work directory.

=item replication_source => $string

If given the server is considered to be a Tarantool replica.

=item logger => $sub

An subroutine called at every time, when tarantool write some thing in a log.
The writed text passed as the first argument. Default is warn.

=item on_die => $sub

An subroutine called on a unexpected tarantool termination.

=back

=cut

sub new {
	my $class = shift; $class = (ref $class)? ref $class : $class;
	# FIXME: must die if no spaces given
	my $self = {
		arena => 0.1,
		cleanup => 1,
		initlua => '-- init.lua --',
		host => '127.0.0.1',
		log_level => 5,
		logger => sub { warn $_[0] },
		on_die => sub { warn "Broken pipe, child is dead?"; },
		port => 6603 + 4 * $Count, # FIXME: auto fitting needed
		replication_source => '',
		root => join("", ("tnt_", map { chr(97 + int(rand(26))) } 1..10)),
		snapshot => '',
		title => "yat" . $Count,
		wal_mode => 'none',
		@_,
	}; $Count++;
	$self->{p_port} = $self->{port};
	$self->{s_port} ||= $self->{port} + 1;
	$self->{a_port} ||= $self->{port} + 2;
	$self->{r_port} ||= $self->{port} + 3;

	bless $self, $class;

	weaken ($Schedule{$self} = $self);

	mkdir($self->{root}); # FIXME: need error hadling

	$self->_config();
	$self->_init_storage();
	$self->_initlua();
	$self;
}

=head2 start option => $value, $cb->($status, $reason)

Run tarantool instance.

=over 4

=item timeout => $timeout

If not After $timeout seconds tarantool will been kelled by the KILL signal if
not started.

=back

=cut

sub start {
	my $self = shift;
	my $cb = pop;
	my %arg = (
		timeout => 60,
		@_
	);

	return $cb->(0, 'Already running') if($self->{pid});

	pipe my $cr, my $pw or die "pipe filed: $!";
	pipe my $pr, my $cw or die "pipe filed: $!";
	autoflush($_) for ($pr, $pw, $cr, $cw);

	return $cb->(0, "Can't fork: $!") unless defined(my $pid = fork);
	if ($pid) {
		close($_) for ($cr, $cw);
		$self->{pid} = $pid;
		$self->{rpipe} = $pr;
		$self->{wpipe} = $pw;
		$self->{nanny} = AnyEvent->child(
			pid => $pid,
			cb => sub {
				$self->{$_} = undef for qw/pid asleep rpipe wpipe nanny/;
				# call on_die only for unexpected termination
				if($self->{dying}) {
					delete $self->{dying};
				} else {
					$self->{on_die}->($self, @_);
				}
			});
		$self->{rh} = AnyEvent::Handle->new(
			fh => $pr,
			on_read => sub { $self->{logger}->(delete $_[0]->{rbuf}) },
			on_error => sub {
				kill 9, $self->{pid} if ($self->{pid} and kill 0, $self->{pid});
			},
		);
		my $i = int($arg{timeout} / 0.1);
		$self->{start_timer} = AnyEvent->timer(
			after => 0.01,
			interval => 0.1,
			cb => sub {
				unless ($self->{pid}) {
					$self->{start_timer} = undef;
					$cb->(0, "Process unexpectedly terminated");
				}
				open my $fh, "<", "/proc/$self->{pid}/cmdline" or
					do { $self->{start_timer} = undef; return $cb->(0, "Tarantool died"); };
				my $status = $self->{replication_source} ? "replica" : "primary";
				if (<$fh> =~ /$status/) {
					$self->{start_timer} = undef;
					$cb->(1, "OK");
				}
				unless($i > 0) {
					kill TERM => $self->{pid};
					$self->{start_timer} = undef;
					$cb->(0, "Timeout exceeding. Process terminated");
				}
				$i--;
			}
		);
	} else {
		close($_) for ($pr, $pw);
		chdir $self->{root};
		open(STDIN, "<&", $cr) or die "Could not dup filehandle: $!";
		open(STDOUT, ">&", $cw) or die "Could not dup filehandle: $!";
		open(STDERR, ">&", $cw) or die "Could not dup filehandle: $!";
		exec "tarantool_box -v -c tarantool.conf";
		die "exec: $!";
	}
}

=head2 stop option => $value, $cb->($status, $reason)

stop tarantool instance

=over 4

=item timeout => $timeout

After $timeout seconds tarantool will been kelled by the KILL signal

=back

=cut

sub stop {
	my $self = shift;
	my $cb = pop;
	my %arg = (
		timeout => 10,
		@_
	);

	return $cb->(1, "Not Running") unless $self->{pid};

	$self->resume() if delete $self->{asleep};

	$self->{dying} = 1;

	my $i = int($arg{timeout} / 0.1);
	$self->{stop_timer} = AnyEvent->timer(
		interval => 0.1,
		cb => sub {
			unless ($self->{pid}) {
				$self->{stop_timer} = undef;
				$cb->(1, "OK");
			}

			unless($i > 0) {
				$self->{stop_timer} = undef;
				kill KILL => $self->{pid};
				$cb->(0, "Killed");
			}
			$i--;
		}
	);
	kill TERM => $self->{pid};
}

=head2 pause

Send STOP signal to instance

=cut

sub pause {
	my $self = shift;
	return unless $self->{pid};
	$self->{asleep} = 1;
	kill STOP => $self->{pid};
}

=head2 resume

Send CONT signal to instance

=cut

sub resume {
	my $self = shift;
	return unless $self->{pid};
	$self->{asleep} = undef;
	kill CONT => $self->{pid};
}

=head2 ro $cb->($status, $reason)

Switch tarantool instance to read only mode.

=cut

sub ro {
	my ($self, $cb) = @_;
	return $cb->(1, "Not Changed") if $self->{replication_source};
	$self->{replication_source} = "$self->{host}:$self->{port}";
	$self->_config();
	$self->admin_cmd("reload configuration", sub {
		$cb->($_[0], $_[0] ? "OK" : "Failed")
	});
}

=head2 rw $cb->($status, $reason)

Switch tarantool instance to write mode.

=cut

sub rw {
	my ($self, $cb) = @_;
	return $cb->(1, "Not Changed") unless $self->{replication_source};
	$self->{replication_source} = "";
	$self->_config();
	$self->admin_cmd("reload configuration", sub {
		$cb->($_[0], $_[0] ? "OK" : "Failed")
	});
}

=head2 admin_cmd $cmd, $cb->($status, $response_or_reason)

Exec a command via the amind port.

=cut

sub admin_cmd {
	my ($self, $cmd, $cb) = @_;
	return if ($self->{afh});
	$self->{afh} = AnyEvent::Handle->new (
		connect => [ $self->{host}, $self->{a_port} ],
		on_connect => sub {
			$_[0]->push_write($cmd . "\n");
		},
		on_connect_error => sub {
			warn "Connection error: $_[1]";
			$_[0]->on_read(undef);
			$_[0]->destroy();
			delete $self->{afh};
			$cb->(0, $_[1]);
		},
		on_error => sub {
			$_[0]->on_read(undef);
			$_[0]->destroy();
			delete $self->{afh};
			$cb->(0, $_[2])
		},
	);
	$self->{afh}->push_read(regex => qr/\x0a\.\.\.\x0a/, sub {
		$_[0]->destroy();
		delete $self->{afh};
		$cb->(1, $_[1]);
	});
}

=head2 times

Return values of utime and stime from /proc/[pid]/stat, converted to seconds

=cut

sub times {
	my $self = shift;
	return unless $self->{pid};
	open my $f, "<", "/proc/$self->{pid}/stat";
	map { $_ / 100 } (split " ", <$f>)[13..14];
}

=head2 sync_start sync_stop sync_ro sync_rw sync_admin_cmd

Aliases for start, stop, ro, rw, admin_cmd respectively, arguments a similar,
but cb not passed.

=cut

{
	no strict 'refs';
	for my $method (qw/start stop ro rw admin_cmd/) {
		*{"Test::Tarantool::sync_$method"} = sub {
			my $self = shift;
			my $cv = AE::cv();
			$self->$method(@_, $cv);
			return $cv->recv;
		}
	}
}


sub _config {
	my $self = shift;
	my $config = do { my $pos = tell DATA; local $/; my $c = <DATA>; seek DATA, $pos, 0; $c };
	$config =~ s/ %\{([^{}]+)\} /$self->{$1}/xsg;
	$config =~ s/ %\{\{(.*?)\}\} /eval "$1" or ''/exsg;
	open my $f, '>', $self->{root} . '/' . 'tarantool.conf' or die "Could not create tnt config : $!";;
	syswrite $f, $config;
}

sub _spaces {
	my $self = shift;
	return $self->{spaces} unless ref $self->{spaces};
	die 'TODO';
}

sub _initlua {
	my $self = shift;
	die 'TODO' if ref $self->{initlua};
	open my $f, '>', $self->{root} . '/' . 'init.lua' or die "Could not create init.lua : $!";;
	syswrite $f, $self->{initlua};
}

sub _init_storage() {
	my $self = shift;
	open my $f, '>', $self->{root} . '/' . '00000000000000000001.snap' or die "Could not create tnt snap: $!";
	syswrite $f, "\x53\x4e\x41\x50\x0a\x30\x2e\x31\x31\x0a\x0a\x1e\xab\xad\x10";
	if ($self->{snapshot} =~ m{(?:^|/)([0-9]{20}\.snap)$}) {
		use Cwd;
		symlink Cwd::abs_path($self->{snapshot}), $self->{root} . '/' . $1;
	}
}

sub DESTROY {
	my $self = shift;
	return unless $Schedule{$self};
	kill TERM => $self->{pid} if $self->{pid};
	if ($self->{cleanup}) {
		opendir my $root, $self->{root} or die "opendir: $!";
		my @unlink = map { (/^[^.]/ && -f "$self->{root}/$_") ? "$self->{root}/$_" : () } readdir($root);
		local $, = ' ';
		unlink @unlink or
			warn "Could not unlink files (@unlink): $!";
		rmdir($self->{root});
	}
	delete $Schedule{$self};
	warn "$self->{title} destroed\n";
}

END {
	for (keys %Schedule) {
		$Schedule{$_}->DESTROY();
	}
}

=head1 AUTHOR

Anton Reznikov, C<< <anton.n.reznikov at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<< <a.reznikov at corp.mail.ru> >>



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Tarantool

=head1 ACKNOWLEDGEMENTS

    Mons Anderson    - The original idia of the module.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Anton Reznikov.

This program is released under the following license: GPL

=cut

1;

__DATA__
custom_proc_title="%{title}"
slab_alloc_arena = %{arena}
bind_ipaddr = %{host}

primary_port = %{p_port}
secondary_port = %{s_port}
admin_port = %{a_port}
replication_port = %{r_port}
%{{ "replication_source = %{replication_source}" if "%{replication_source}" }}

script_dir = .
work_dir = .
wal_mode = %{wal_mode}
log_level = %{log_level}
#logger = "cat - >> tarantool.log"

%{{ $self->_spaces }}
