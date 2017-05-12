package Twiggy::Prefork;

use strict;
use warnings;

our $VERSION = '0.08';

1;
__END__

=head1 NAME

Twiggy::Prefork - Preforking AnyEvent HTTP server for PSGI

=head1 SYNOPSIS

  $ plackup -s Twiggy::Prefork -a app.psgi
  
=head1 DESCRIPTION

Twiggy::Prefork is Preforking AnyEvent HTTP server for PSGI based on Twiggy. This server supports,

=over 4

=item Min/Max Request Per Child

supports Min/Max Request Per Child feature. 

=item Superdaemon aware

Supports L<Server::Starter> for hot deploy and
graceful restarts.

To use it, instead of the usual:

    plackup --server Twiggy::Prefork --port 8111 app.psgi

install L<Server::Starter> and use:

    start_server --port 8111 plackup --server Twiggy::Prefork app.psgi

=back

=head1 OPTIONS

=over 4

=item max_workers

number of worker processes (default: 10)

=item max_reqs_per_child

max. number of requests to be handled before a worker process exits. If passed 0, child process is not existed by number of requests (default: 100).

=item min_reqs_per_child

if set, randomizes the number of requests handled by a single worker process between the value and that supplied by --max-reqs-per-child (default: none)

=back

=head1 PSGI extensions

=over 4

=item psgix.exit_guard

AnyEvent::CondVar object. You can make graceful stop mechanism with this variable.

  use Coro;
  use AnyEvent;

  my $channel = Coro::Channel->new(100);

  async {
    while(1){
      my $q = $channel->get;
      # works..
      $q[0]->end;
    }
  };

  #psgi app
  sub {
    my $env = shift;
    my $cv = AE::cv;
    async {
      $env->{psgix.exit_guard}->begin; 
      $channel->put([$env->{psgix.exit_guard}]);
      $cv->send;
    };
    return sub {
      my $start_response = shift;
      $cv->cb(sub {
        $start_response->([200,['Content-Type'=>'text/plain'],['OK']]);
      });
    }
  }

Block Twiggy::Prefork worker process exiting until your jobs done.

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

Shigeki Morimoto

=head1 SEE ALSO

L<Twiggy>, L<Parallel::Prefork>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
