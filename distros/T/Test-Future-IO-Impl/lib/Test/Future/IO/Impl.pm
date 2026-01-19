#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2021-2026 -- leonerd@leonerd.org.uk

package Test::Future::IO::Impl 0.17;

use v5.14;
use warnings;

use Test2::V0;
use Test2::API ();

use Errno qw( EINVAL EPIPE );
use IO::Handle;
use IO::Poll qw( POLLIN POLLOUT POLLHUP POLLERR );
use Socket qw(
   pack_sockaddr_in sockaddr_family INADDR_LOOPBACK
   AF_INET AF_UNIX SOCK_DGRAM SOCK_STREAM PF_UNSPEC
);
use Time::HiRes qw( sleep time );

use Exporter 'import';
our @EXPORT = qw( run_tests );

=head1 NAME

C<Test::Future::IO::Impl> - acceptance tests for C<Future::IO> implementations

=head1 SYNOPSIS

=for highlighter language=perl

   use Test::More;
   use Test::Future::IO::Impl;

   use Future::IO;
   use Future::IO::Impl::MyNewImpl;

   run_tests 'sleep';

   done_testing;

=head1 DESCRIPTION

This module contains a collection of acceptance tests for implementations of
L<Future::IO>.

=cut

=head1 FUNCTIONS

=cut

my $errstr_EPIPE = do {
   # On MSWin32 we don't get EPIPE, but EINVAL
   local $! = $^O eq "MSWin32" ? EINVAL : EPIPE; "$!";
};

my $errstr_ECONNREFUSED = do {
   local $! = Errno::ECONNREFUSED; "$!";
};

sub time_about(&@)
{
   my ( $code, $want_time, $name ) = @_;
   my $ctx = Test2::API::context;

   my $t0 = time();
   $code->();
   my $t1 = time();

   my $got_time = $t1 - $t0;
   $ctx->ok(
      $got_time >= $want_time * 0.9 && $got_time <= $want_time * 1.5, $name
   ) or
      $ctx->diag( sprintf "Test took %.3f seconds", $got_time );

   $ctx->release;
}

=head2 run_tests

   run_tests @suitenames;

Runs a collection of tests against C<Future::IO>. It is expected that the
caller has already loaded the specific implementation module to be tested
against before this function is called.

=cut

sub run_tests
{
   foreach my $test ( @_ ) {
      my $code = __PACKAGE__->can( "run_${test}_test" )
         or die "Unrecognised test suite name $test";
      __PACKAGE__->$code();
   }
}

=head1 TEST SUITES

The following test suite names may be passed to the L</run_tests> function:

=cut

=head2 accept

Tests the C<< Future::IO->accept >> method.

=cut

sub run_accept_test
{
   require IO::Socket::INET;

   my $serversock = IO::Socket::INET->new(
      Type      => Socket::SOCK_STREAM(),
      LocalAddr => "localhost",
      LocalPort => 0,
      Listen    => 1,
   ) or die "Cannot socket()/listen() - $@";

   $serversock->blocking( 0 );

   my $f = Future::IO->accept( $serversock );

   # Some platforms have assigned 127.0.0.1 here; others have left 0.0.0.0
   # If it's still 0.0.0.0, then guess that maybe connecting to 127.0.0.1 will
   # work
   my $sockname = ( $serversock->sockhost ne "0.0.0.0" )
      ? $serversock->sockname
      : pack_sockaddr_in( $serversock->sockport, INADDR_LOOPBACK );

   my $clientsock = IO::Socket::INET->new(
      Type => Socket::SOCK_STREAM(),
   ) or die "Cannot socket() - $@";
   $clientsock->connect( $sockname ) or die "Cannot connect() - $@";

   my $acceptedsock = $f->get;

   ok( $clientsock->peername eq $acceptedsock->sockname, 'Accepted socket address matches' );
}

=head2 connect

Tests the C<< Future::IO->connect >> method.

=cut

sub run_connect_test
{
   require IO::Socket::INET;

   my $serversock = IO::Socket::INET->new(
      Type      => Socket::SOCK_STREAM(),
      LocalAddr => "localhost",
      LocalPort => 0,
      Listen    => 1,
   ) or die "Cannot socket()/listen() - $@";

   # Some platforms have assigned 127.0.0.1 here; others have left 0.0.0.0
   # If it's still 0.0.0.0, then guess that maybe connecting to 127.0.0.1 will
   # work
   my $sockname = ( $serversock->sockhost ne "0.0.0.0" )
      ? $serversock->sockname
      : pack_sockaddr_in( $serversock->sockport, INADDR_LOOPBACK );

   # ->connect success
   {
      my $clientsock = IO::Socket::INET->new(
         Type => Socket::SOCK_STREAM(),
      ) or die "Cannot socket() - $@";
      $clientsock->blocking( 0 );

      my $f = Future::IO->connect( $clientsock, $sockname );

      $f->get;

      my $acceptedsock = $serversock->accept;
      ok( $clientsock->peername eq $acceptedsock->sockname, 'Accepted socket address matches' );
   }

   $serversock->close;
   undef $serversock;

   # I really hate this, but apparently tests on most OSes will fail if we
   # don't do this. Technically Linux can get away without it but it's only
   # 100msec, nobody will notice
   sleep 0.1;

   # ->connect fails
   {
      my $clientsock = IO::Socket::INET->new(
         Type => Socket::SOCK_STREAM(),
      ) or die "Cannot socket() - $@";
      $clientsock->blocking( 0 );

      my $f = Future::IO->connect( $clientsock, $sockname );

      ok( !eval { $f->get; 1 }, 'Future::IO->connect fails on closed server' );

      is( [ $f->failure ],
         [ "connect: $errstr_ECONNREFUSED\n", connect => $clientsock, $errstr_ECONNREFUSED ],
         'Future::IO->connect failure' );
   }
}

=head2 poll

I<Since version 0.17.>

Tests the C<< Future::IO->poll >> method.

=cut

# because the Future::IO default impl cannot handle HUP
sub run_poll_no_hup_test
{
   # POLLIN
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

      $wr->autoflush();
      $wr->print( "BYTES" );

      my $f = Future::IO->poll( $rd, POLLIN );

      is( scalar $f->get, POLLIN, "Future::IO->poll yields POLLIN on readable filehandle" );

      my $f1 = Future::IO->poll( $rd, POLLIN );
      my $f2 = Future::IO->poll( $rd, POLLIN );

      is( [ scalar $f1->get, scalar $f2->get ], [ POLLIN, POLLIN ],
         'Future::IO->poll can enqueue two POLLIN tests' );
   }

   # POLLOUT
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

      my $f = Future::IO->poll( $wr, POLLOUT );

      is( scalar $f->get, POLLOUT, "Future::IO->poll yields POLLOUT on writable filehandle" );

      my $f1 = Future::IO->poll( $wr, POLLOUT );
      my $f2 = Future::IO->poll( $wr, POLLOUT );

      is( [ scalar $f1->get, scalar $f2->get ], [ POLLOUT, POLLOUT ],
         'Future::IO->poll can enqueue two POLLOUT tests' );
   }

   # POLLIN+POLLOUT at once
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

      $wr->autoflush();
      $wr->print( "BYTES" );

      my ( $frd, $fwr );

      # IN+OUT on reading end
      $frd = Future::IO->poll( $rd, POLLIN );
      $fwr = Future::IO->poll( $rd, POLLOUT );

      is( scalar $frd->get, POLLIN, "Future::IO->poll yields POLLIN on readable with simultaneous POLLOUT" );
      # Don't assert on what $fwr saw here, as OSes/impls might differ
      $fwr->cancel;

      # IN+OUT on writing end
      $frd = Future::IO->poll( $wr, POLLIN );
      $fwr = Future::IO->poll( $wr, POLLOUT );

      is( scalar $fwr->get, POLLOUT, "Future::IO->poll yields POLLOUT on writable with simultaneous POLLIN" );
      # Don't assert on what $frd saw here, as OSes/impls might differ
      $frd->cancel;
   }
}

sub run_poll_test
{
   run_poll_no_hup_test();

   # POLLHUP
   {
      # closing the writing end of a pipe puts the reading end at hangup condition
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
      close $wr;

      my $f = Future::IO->poll( $rd, POLLHUP );

      is( scalar $f->get, POLLHUP, "Future::IO->poll yields POLLHUP on hangup-in filehandle" );
   }

   # POLLERR
   {
      # closing the reading end of a pipe puts the writing end at error condition, because EPIPE
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
      close $rd;

      my $f = Future::IO->poll( $wr, POLLOUT );

      # We expect at least POLLERR, we might also see POLLOUT or POLLHUP as
      # well but lets not care about that
      my $got_revents = $f->get;
      is( $got_revents & POLLERR, POLLERR, "Future::IO->poll yields at-least POLLERR on hangup-out filehandle" );
   }
}

=head2 recv, recvfrom

I<Since version 0.15.>

Tests the C<< Future::IO->recv >> and C<< Future::IO->recvfrom >> methods.

=cut

# Getting a read/write socket pair which has working addresses is nontrivial.
# AF_UNIX sockets created by socketpair() literally have no addresses. AF_INET
# sockets would always have an address, but socketpair() can't create
# connected AF_INET pairs on most platforms. Grr.
# We'll make our own socketpair-alike that does.
sub _socketpair_INET_DGRAM
{
   my ( $connected ) = @_;
   $connected //= 1;

   require IO::Socket::INET;

   # The IO::Socket constructors are unhelpful to us here; we'll do it ourselves
   my $rd = IO::Socket::INET->new
      ->socket( AF_INET, SOCK_DGRAM, 0 ) or die "Cannot socket rd - $!";
   $rd->bind( pack_sockaddr_in( 0, INADDR_LOOPBACK ) ) or die "Cannot bind rd - $!";

   my $wr = IO::Socket::INET->new
      ->socket( AF_INET, SOCK_DGRAM, 0 );
   $wr->connect( $rd->sockname ) or die "Cannot connect wr - $!"
      if $connected;

   return ( $rd, $wr );
}

sub run_recv_test     { _run_recv_test( 'recv', 0 ); }
sub run_recvfrom_test { _run_recv_test( 'recvfrom', 1 ); }
sub _run_recv_test
{
   my ( $method, $expect_fromaddr ) = @_;

   # yielding bytes
   {
      my ( $rd, $wr ) = _socketpair_INET_DGRAM();

      $wr->autoflush();
      $wr->send( "BYTES" );

      my $f = Future::IO->$method( $rd, 5 );

      is( scalar $f->get, "BYTES", "Future::IO->$method yields bytes from socket" );
      # We can't know exactly what address it will be but 
      my $fromaddr = ( $f->get )[1];
      ok( defined $fromaddr, "Future::IO->$method also yields a fromaddr" )
         if $expect_fromaddr;
      is( sockaddr_family( $fromaddr ), AF_INET, "Future::IO->$method fromaddr is valid AF_INET address" )
         if $expect_fromaddr;
   }

   # From here onwards we don't need working sockaddr/peeraddr so we can just
   # use simpler IO::Socket::UNIX->socketpair instead

   return if $^O eq "MSWin32";

   require IO::Socket::UNIX;

   # yielding EOF
   {
      my ( $rd, $wr ) = IO::Socket::UNIX->socketpair( AF_UNIX, SOCK_STREAM, PF_UNSPEC )
         or die "Cannot socketpair() - $!";
      $wr->close; undef $wr;

      my $f = Future::IO->$method( $rd, 1 );

      is ( [ $f->get ], [], "Future::IO->$method yields nothing on EOF" );
   }

   # can be cancelled
   {
      my ( $rd, $wr ) = IO::Socket::UNIX->socketpair( AF_UNIX, SOCK_STREAM, PF_UNSPEC )
         or die "Cannot socketpair() - $!";

      $wr->autoflush();
      $wr->send( "BYTES" );

      my $f1 = Future::IO->$method( $rd, 3 );
      my $f2 = Future::IO->$method( $rd, 3 );

      $f1->cancel;

      # At this point we don't know if $f1 performed its recv or not. There's
      # two possible things we might see from $f2.

      like( scalar $f2->get, qr/^(?:BYT|ES)$/,
         "Result of second Future::IO->$method after first is cancelled" );
   }
}

=head2 send

I<Since version 0.15.>

Tests the C<< Future::IO->send >> method.

=cut

sub run_send_test
{
   # success
   {
      # An unconnected socketpair to prove that ->send used the correct address later on
      my ( $rd, $wr ) = _socketpair_INET_DGRAM( 0 );

      my $f = Future::IO->send( $wr, "BYTES", 0, $rd->sockname );

      is( scalar $f->get, 5, 'Future::IO->send yields sent count' );

      $rd->recv( my $buf, 5 );
      is( $buf, "BYTES", 'Future::IO->send sent bytes' );
   }

   # From here onwards we don't need working sockaddr/peeraddr so we can just
   # use simpler IO::Socket::UNIX->socketpair instead

   return if $^O eq "MSWin32";

   require IO::Socket::UNIX;

   # yielding EAGAIN
   SKIP: {
      $^O eq "MSWin32" and skip "MSWin32 doesn't do EAGAIN properly", 2;

      my ( $rd, $wr ) = IO::Socket::UNIX->socketpair( AF_UNIX, SOCK_STREAM, PF_UNSPEC )
         or die "Cannot socketpair() - $!";
      $wr->blocking( 0 );

      # Attempt to fill the buffer
      $wr->write( "X" x 4096 ) for 1..256;

      my $f = Future::IO->send( $wr, "more" );

      ok( !$f->is_ready, '$f is still pending' );

      # Now make some space. We need to drain it quite a lot for mechanisms
      # like ppoll() to be happy that the socket is actually writable
      $rd->blocking( 0 );
      $rd->read( my $buf, 4096 ) for 1..256;

      is( scalar $f->get, 4, 'Future::IO->send yields written count' );
   }

   # yielding EPIPE
   {
      my ( $rd, $wr ) = IO::Socket::UNIX->socketpair( AF_UNIX, SOCK_STREAM, PF_UNSPEC )
         or die "Cannot socketpair() - $!";
      $rd->close; undef $rd;

      local $SIG{PIPE} = 'IGNORE';

      my $f = Future::IO->send( $wr, "BYTES" );

      $f->await;
      ok( $f->is_ready, '->send future is now ready after EPIPE' );

      # Sometimes we get EPIPE out of a send(2) system call (e.g Linux).
      # Sometimes we get a croak out of IO::Socket->send itself because it
      # checked getpeername() and found it missing (e.g. most BSDs). We
      # shouldn't be overly concerned with _what_ the failure is, only that
      # it failed somehow.
      ok( scalar $f->failure, 'Future::IO->send failed after peer closed' );
   }

   # can be cancelled
   {
      my ( $rd, $wr ) = IO::Socket::UNIX->socketpair( AF_UNIX, SOCK_STREAM, PF_UNSPEC )
         or die "Cannot socketpair() - $!";

      my $f1 = Future::IO->send( $wr, "BY" );
      my $f2 = Future::IO->send( $wr, "TES" );

      $f1->cancel;

      is( scalar $f2->get, 3, 'Future::IO->send after cancelled one still works' );

      $rd->read( my $buf, 3 );

      # At this point we don't know if $f1 performed its send or not. There's
      # two possible things we might see from the buffer. Either way, the
      # presence of a 'T' means that $f2 ran.

      like( $buf, qr/^(?:BYT|TES)$/,
         "A second Future::IO->send takes place after first is cancelled" );
   }
}

=head2 sleep

Tests the C<< Future::IO->sleep >> and C<< Future::IO->alarm >> methods.

The two methods are combined in one test suite as they are very similar, and
neither is long or complicated.

=cut

sub run_sleep_test
{
   time_about sub {
      Future::IO->sleep( 0.2 )->get;
   }, 0.2, 'Future::IO->sleep( 0.2 ) sleeps 0.2 seconds';

   time_about sub {
      my $f1 = Future::IO->sleep( 0.1 );
      my $f2 = Future::IO->sleep( 0.3 );
      $f1->cancel;
      $f2->get;
   }, 0.3, 'Future::IO->sleep can be cancelled';

   {
      my $f1 = Future::IO->sleep( 0.1 );
      my $f2 = Future::IO->sleep( 0.3 );

      is( $f2->await, $f2, '->await returns Future' );
      ok( $f2->is_ready, '$f2 is ready after ->await' );
      ok( $f1->is_ready, '$f1 is also ready after ->await' );
   }

   time_about sub {
      Future::IO->alarm( time() + 0.2 )->get;
   }, 0.2, 'Future::IO->alarm( now + 0.2 ) sleeps 0.2 seconds';
}

=head2 read, sysread

Tests the C<< Future::IO->sysread >> or C<< Future::IO->sysread >> method.

These two test suites are identical other than the name of the method they
invoke. The two exist because of the method rename that happened at
C<Future::IO> version 0.17.

=cut

sub run_read_test    { _run_read_test( 'read' ); }
sub run_sysread_test { _run_read_test( 'sysread' ); }
sub _run_read_test
{
   my ( $method ) = @_;

   # yielding bytes
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

      $wr->autoflush();
      $wr->print( "BYTES" );

      my $f = Future::IO->$method( $rd, 5 );

      is( scalar $f->get, "BYTES", "Future::IO->$method yields bytes from pipe" );
   }

   # yielding EOF
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
      $wr->close; undef $wr;

      my $f = Future::IO->$method( $rd, 1 );

      is( [ $f->get ], [], "Future::IO->$method yields nothing on EOF" );
   }

   # TODO: is there a nice portable way we can test for an IO error?

   # can be cancelled
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

      $wr->autoflush();
      $wr->print( "BYTES" );

      my $f1 = Future::IO->$method( $rd, 3 );
      my $f2 = Future::IO->$method( $rd, 3 );

      $f1->cancel;

      # At this point we don't know if $f1 performed its read or not. There's
      # two possible things we might see from $f2.

      like( scalar $f2->get, qr/^(?:BYT|ES)$/,
         "Result of second Future::IO->$method after first is cancelled" );
   }
}

=head2 write, syswrite

Tests the C<< Future::IO->write >> or C<< Future::IO->syswrite >> method.

These two test suites are identical other than the name of the method they
invoke. The two exist because of the method rename that happened at
C<Future::IO> version 0.17.

=cut

sub run_write_test    { _run_write_test( 'write' ); }
sub run_syswrite_test { _run_write_test( 'syswrite' ); }
sub _run_write_test
{
   my ( $method ) = @_;

   # success
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

      my $f = Future::IO->$method( $wr, "BYTES" );

      is( scalar $f->get, 5, "Future::IO->$method yields written count" );

      $rd->read( my $buf, 5 );
      is( $buf, "BYTES", "Future::IO->$method wrote bytes" );
   }

   # yielding EAGAIN
   SKIP: {
      $^O eq "MSWin32" and skip "MSWin32 doesn't do EAGAIN properly", 2;

      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
      $wr->blocking( 0 );

      # Attempt to fill the pipe
      $wr->$method( "X" x 4096 ) for 1..256;
      # clear the error on the filehandle to stop perl printing a warning
      $wr->clearerr;

      my $f = Future::IO->$method( $wr, "more" );

      ok( !$f->is_ready, '$f is still pending' );

      # Now make some space
      $rd->read( my $buf, 4096 );

      is( scalar $f->get, 4, "Future::IO->$method yields written count" );
   }

   # yielding EPIPE
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";
      $rd->close; undef $rd;

      local $SIG{PIPE} = 'IGNORE';

      my $f = Future::IO->$method( $wr, "BYTES" );

      ok( !eval { $f->get }, "Future::IO->$method fails on EPIPE" );

      is( [ $f->failure ],
         [ "syswrite: $errstr_EPIPE\n", syswrite => $wr, $errstr_EPIPE ],
         "Future::IO->$method failure for EPIPE" );
   }

   # can be cancelled
   {
      pipe my ( $rd, $wr ) or die "Cannot pipe() - $!";

      my $f1 = Future::IO->$method( $wr, "BY" );
      my $f2 = Future::IO->$method( $wr, "TES" );

      $f1->cancel;

      is( scalar $f2->get, 3, "Future::IO->$method after cancelled one still works" );

      $rd->read( my $buf, 3 );

      # At this point we don't know if $f1 performed its write or not. There's
      # two possible things we might see from the buffer. Either way, the
      # presence of a 'T' means that $f2 ran.

      like( $buf, qr/^(?:BYT|TES)$/,
         "A second Future::IO->$method takes place after first is cancelled" );
   }
}

=head2 waitpid

Tests the C<< Future::IO->waitpid >> method.

=cut

sub run_waitpid_test
{
   # pre-exit
   {
      defined( my $pid = fork() ) or die "Unable to fork() - $!";
      if( $pid == 0 ) {
         # child
         exit 3;
      }

      sleep 0.1;

      my $f = Future::IO->waitpid( $pid );
      is( scalar $f->get, ( 3 << 8 ), 'Future::IO->waitpid yields child wait status for pre-exit' );
   }

   # post-exit
   {
      defined( my $pid = fork() ) or die "Unable to fork() - $!";
      if( $pid == 0 ) {
         # child
         sleep 0.1;
         exit 4;
      }

      my $f = Future::IO->waitpid( $pid );
      is( scalar $f->get, ( 4 << 8 ), 'Future::IO->waitpid yields child wait status for post-exit' );
   }
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
