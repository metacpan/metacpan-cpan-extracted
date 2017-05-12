use strict;
use warnings;
use AE;
use AnyEvent::Socket;
use AnyEvent::Handle;

my($port) = @ARGV;

my @w;
push @w, AE::timer 10, 0, sub { warn "timeout!"; exit 2 };

my $cv = AE::cv;

tcp_connect '127.0.0.1', $port, sub {
  my($fh) = @_;

  my $handle = AnyEvent::Handle->new(
    fh => $fh,
  );

  $handle->on_read(sub {
    $handle->push_read( line => sub {
      my($handle, $line) = @_;
      print "$line\n";
      $cv->send(22);
    });
  });

};

exit $cv->recv;
