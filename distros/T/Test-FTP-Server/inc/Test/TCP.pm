#line 1
package Test::TCP;
use strict;
use warnings;
use 5.00800;
our $VERSION = '2.22';
use base qw/Exporter/;
use Test::SharedFork 0.12;
use Test::More ();
use Config;
use POSIX;
use Time::HiRes ();
use Carp ();
use Net::EmptyPort qw(empty_port check_port);

our @EXPORT = qw/ empty_port test_tcp wait_port /;

# process does not die when received SIGTERM, on win32.
my $TERMSIG = $^O eq 'MSWin32' ? 'KILL' : 'TERM';

sub test_tcp {
    my %args = @_;
    for my $k (qw/client server/) {
        die "missing mandatory parameter $k" unless exists $args{$k};
    }
    my $server_code = delete $args{server};
    my $client_code = delete $args{client};

    my $server = Test::TCP->new(
        code => $server_code,
        %args,
    );
    $client_code->($server->port, $server->pid);
    undef $server; # make sure
}

sub wait_port {
    my ($host, $port, $max_wait);
    if (@_ && ref $_[0] eq 'HASH') {
        $host = $_[0]->{host};
        $port = $_[0]->{port};
        $max_wait = $_[0]->{max_wait};
    } elsif (@_ == 3) {
        # backward compat
        ($port, (my $sleep), (my $retry)) = @_;
        $max_wait = $sleep * $retry;
    } else {
        ($port, $max_wait) = @_;
    }
    $host = '127.0.0.1'
        unless defined $host;
    $max_wait ||= 10;

    Net::EmptyPort::wait_port({ host => $host, port => $port, max_wait => $max_wait })
        or die "cannot open port: $host:$port";
}

# ------------------------------------------------------------------------- 
# OO-ish interface

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    Carp::croak("missing mandatory parameter 'code'") unless exists $args{code};
    my $self = bless {
        auto_start => 1,
        max_wait   => 10,
        host       => '127.0.0.1',
        _my_pid    => $$,
        %args,
    }, $class;
    if ($self->{listen}) {
        $self->{socket} ||= Net::EmptyPort::listen_socket({
            host => $self->{host},
            proto => $self->{proto},
        }) or die "Cannot listen: $!";
        $self->{port} = $self->{socket}->sockport;
    }
    else {
        $self->{port} ||= empty_port({ host => $self->{host} });
    }
    $self->start()
      if $self->{auto_start};
    return $self;
}

sub pid  { $_[0]->{pid} }
sub port { $_[0]->{port} }

sub start {
    my $self = shift;
    my $pid = fork();
    die "fork() failed: $!" unless defined $pid;

    if ( $pid ) { # parent process.
        $self->{pid} = $pid;
        Test::TCP::wait_port({ host => $self->{host}, port => $self->port, max_wait => $self->{max_wait} })
            unless $self->{socket};
        return;
    } else { # child process
        $self->{code}->($self->{socket} || $self->port);
        # should not reach here
        if (kill 0, $self->{_my_pid}) { # warn only parent process still exists
            warn("[Test::TCP] Child process does not block(PID: $$, PPID: $self->{_my_pid})");
        }
        exit 0;
    }
}

sub stop {
    my $self = shift;

    return unless defined $self->{pid};
    return unless $self->{_my_pid} == $$;

    # This is a workaround for win32 fork emulation's bug.
    #
    # kill is inherently unsafe for pseudo-processes in Windows
    # and the process calling kill(9, $pid) may be destabilized
    # The call to Sleep will decrease the frequency of this problems
    #
    # SEE ALSO:
    #   http://www.gossamer-threads.com/lists/perl/porters/261805
    #   https://rt.cpan.org/Ticket/Display.html?id=67292
    Win32::Sleep(0) if $^O eq "MSWin32"; # will relinquish the remainder of its time slice

        kill $TERMSIG => $self->{pid};

    Win32::Sleep(0) if $^O eq "MSWin32"; # will relinquish the remainder of its time slice


    local $?; # waitpid modifies original $?.
    LOOP: while (1) {
        my $kid = waitpid( $self->{pid}, 0 );
        if ($^O ne 'MSWin32') { # i'm not in hell
            if (POSIX::WIFSIGNALED($?)) {
                my $signame = (split(' ', $Config{sig_name}))[POSIX::WTERMSIG($?)];
                if ($signame =~ /^(ABRT|PIPE)$/) {
                    Test::More::diag("your server received SIG$signame");
                }
            }
        }
        if ($kid == 0 || $kid == -1) {
            last LOOP;
        }
    }
    undef $self->{pid};
}

sub DESTROY {
    my $self = shift;
    local $@;
    $self->stop();
}

1;
__END__

#line 453
