package Test::ttserver;

use strict;
use warnings;
use Cwd;
use File::Temp;
use File::Path;
use IO::File;
use POSIX qw/SIGTERM WNOHANG :sys_wait_h/;
use Time::HiRes 'sleep';
use Test::TCP;

our $VERSION = '0.003';
$VERSION = eval $VERSION;

our $errstr;
our @SearchPaths = qw(/usr/bin /usr/local/bin);
our @BooleanArgs = qw(dmn kl ld le uas rcc);
our %Defaults    = (
    debug      => 0,
    auto_start => 1,
    base_dir   => undef,
    bin        => undef,
);

sub new {
    my $class  = shift;
    my $dbname = shift || '';
    my $self = bless +{
        %Defaults,
        @_ == 1 ? %{$_[0]} : @_,
    }, $class;

    $self->{'bin'} = $self->_find_bin or return;

    if ( defined $self->{'base_dir'} && $self->{'base_dir'} !~ m{^/} ) {
        $self->{'base_dir'} = getcwd . '/' . $self->{'base_dir'}
    } else {
        $self->{'base_dir'} = File::Temp::tempdir(
            CLEANUP => $ENV{TEST_TTSERVE_PRESERVE} ? undef : 1,
        );
    }

    my %args;
    for (keys %$self) {
        $args{$_} = delete $self->{$_} unless exists $Defaults{$_};
    }
    $args{'pid'}    = $self->{'base_dir'} . '/tmp/pid';
    $args{'host'} ||= $self->host;
    $args{'port'} ||= $self->port;
    $self->{'args'} = \%args;

    $self->{'dbname'} = $dbname ? $self->{'base_dir'} .'/tmp/'. $dbname : '';

    if ( $self->{'auto_start'} ) {
        $self->setup;
        $self->start;
    }

    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->stop if defined $self->pid;
}

sub setup {
    my $self = shift;
    mkpath( $self->{'base_dir'} . '/tmp', { verbose => $self->{'debug'} });
}

sub start {
    my $self = shift;
    return if defined $self->pid;

    my $log_file = $self->{'base_dir'} . '/tmp/ttserver.log';
    my $log_fh = IO::File->new($log_file, O_WRONLY|O_APPEND|O_CREAT)
        or die qq/failed to create log file: $! "$log_file"/;

    my $pid = fork;
    die qq/failed to fork: $!/ unless defined $pid;

    if ( $pid == 0 ) {
        my $bin  = $self->{'bin'};
        my $args = $self->{'args'};
        my %bool; @bool{@BooleanArgs} = (1) x @BooleanArgs;
        my @command = (
            $self->{'bin'},
            ( map {
                $bool{$_} ? "-$_" : ("-$_" => $args->{$_})
            } (keys %$args) ),
            $self->{'dbname'},
        );
        pop @command unless @command and defined $command[-1];
        warn "@command\n" if $self->{'debug'};
        open STDOUT, '>&', $log_fh or die qq/failed to dup: $! "stdout"/;
        open STDERR, '>&', $log_fh or die qq/failed to dup: $! "stderr"/;
        exec @command;
        die qq/failed to launch ttserver: $? "$bin"/;
    }

    $log_fh->close;
    while (! -e $self->{'args'}{'pid'}) {
        if ( 0 < waitpid $pid, WNOHANG ) {
            die qq/*** failed to launch ttserver ***\n/ . $self->_get_log( $log_file );
        }
        sleep 0.1;
    }

    $self->{'child'} = $pid;
}

sub stop {
    my ( $self, $sig ) = @_;
    return unless defined $self->pid;
    $sig ||= SIGTERM;
    kill $sig, $self->pid;
    1 while ( 0 >= waitpid $self->pid, 0 );
    my $is_exited = WIFEXITED( $? );
    delete $self->{'child'};
    # might remain for example when sending SIGKILL
    unlink $self->{'args'}{'pid'};
    return $is_exited;
}

sub socket    { ($_[0]->host, $_[0]->port) }
sub host      { shift->{'args'}{'host'} || '127.0.0.1' }
sub port      { shift->{'args'}{'port'} || empty_port  }
sub pid       { shift->{'child'}         }
sub is_up     { shift->{'child'} ? 1 : 0 }
sub is_down   { shift->is_up ? 0 : 1     }
sub pid_file  { shift->{'args'}{'pid'}   }
sub args      { shift->{'args'}          }

sub _find_bin {
    my $self = shift;

    my @paths = @SearchPaths;
    push @paths, split ':', $ENV{'PATH'} if defined $ENV{'PATH'};

    for my $path (@paths) {
        my $bin = $path . '/ttserver';
        return $bin if -x $bin;
    }

    $errstr = "could not find ttserver, please set appropriate PATH";
    return;
}

sub _get_log {
    my ( $self, $log_file ) = @_;
    my $log = '';
    if ( my $log_fh = IO::File->new($log_file, O_RDONLY) ) {
        $log = do { local $/; <$log_fh> };
        $log_fh->close;
    }
    return $log;
}

1;

__END__

=head1 NAME

Test::ttserver - ttserver runner for tests

=head1 SYNOPSIS

  use Test::More;
  use Test::ttserver;
  use TokyoTyrant;

  my $ttserver = Test::ttserver->new
      or plan 'skip_all' => $Test::ttserver::errstr;

  plan 'tests' => XXX;

  my $rdb = TokyoTyrant::RDB->new;
  $rdb->open( $ttserver->socket );
  ...

=head1 DESCRIPTION

C<Test::ttserver> automatically setups a ttserver instance in a temporary
directory, and destroys it when the perl script exits.

ttserver is the managing server of the database instance of the Tokyo Tyrant
that is a network interface of the Tokyo Cabinet.

=head1 CONSTRUCTOR

  # on memory database
  my $ttserver = Test::ttserver->new(undef,
      debug => 1,
      port  => 101978,
  );

  Ex.) Dual Master

  # ttserver -port 1978 -ulog ulog-a -sid 1 -mhost localhost \
  #     -mport 1979 -rts a.rts casket-a.tch
  my $ttserver_a = Test::ttserver->new('casket-a.tch',
      port  => 1978,
      ulog  => 'ulog-a',
      sid   => 1,
      mhost => 'localhost',
      mport => 1979,
      rts   => 'a.rts',
  ) or plan 'skip_all' => $Test::ttserver::errstr;

  # ttserver -port 1979 -ulog ulog-b -sid 2 -mhost localhost \
  #     -mport 1978 -rts b.rts casket-b.tch
  my $ttserver_b = Test::ttserver->new('casket-b.tch',
      port  => 1979,
      ulog  => 'ulog-b',
      sid   => 2,
      mhost => 'localhost',
      mport => 1978,
      rts   => 'b.rts',
  ) or plan 'skip_all' => $Test::ttserver::errstr;

=head1 METHODS

=head2 new( [$dbname] [, %options] )

Create and run a ttserver instance.  The instance is terminated when the
returned object is being DESTROYed.  If required programs (ttserver) were
not found, the function returns undef and sets appropriate message to
$Test::ttserver::errstr.

ttserver ups as "on memory database" if $dbname is specified undef.

$dbname must be named *.tch or *.tcb or *.tcf.  See also the manual of Tokyo
Tyrant and Tokyo Cabinet for details.

=head2 base_dir

Returns directory under which the ttserver instance is being created.  The
property can be set as a parameter of the C<new> function, in which case
the directory will not be removed at exit.

=head2 pid

Returns process id of ttserver (or undef if not running).

=head2 socket

=head2 host

=head2 port

returns the host and port where server is bound on.

=head2 start

Starts ttserver.  returns process id of ttserver if succeed.

=head2 stop

Stops ttserver.  returns true if succeed.

=head2 setup

Setups the ttserver instance.

returns port where server is bound on.

=head2 is_up

=head2 is_down

returns the value of boolean that server is up or down.

=head2 pid_file

returns the file path of process id of ttserver.

=head2 args

returns the argument values when ttserver was started.

=head1 SEE ALSO

L<TokyoTyrant>, L<TokyoCabinet>

=over 4

=item http://fallabs.com/tokyotyrant/

=item http://fallabs.com/tokyocabinet/

=back

=head1 AUTHOR

Craftworks, C<< <craftwork at cpan org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-ttserver@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright (C) 2009 Craftworks, All Rights Reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
