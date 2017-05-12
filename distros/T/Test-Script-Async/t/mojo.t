use strict;
use warnings;
BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll'; $ENV{DEVEL_HIDE_VERBOSE} = 0 }
use Test2::Require::Module 'Devel::Hide';
use Test2::Require::Module 'Capture::Tiny';
use Devel::Hide 'EV';
use Test2::Bundle::Extended;
use Test2::Require::Module 'Mojolicious' => 6.02;
use Test2::Require::Module 'Mojolicious' => 6.02;
use Mojo::IOLoop;
use Mojo::Reactor;
use Mojo::URL;
use Mojo::Server::Daemon;
use Mojolicious::Lite;
use Test::Script::Async;
use IO::Socket::INET;
use Capture::Tiny qw( capture );

plan 6;

get '/foo' => sub {
  my($c) = @_;
  $c->render(text => 'Platypus Man');
};

app->log(My::Log->new);

isnt(Mojo::Reactor->detect, 'Mojo::Reactor::EV', "Mojo::Reactor->detect = @{[ Mojo::Reactor->detect ]}");

my $url = Mojo::URL->new("http://127.0.0.1");
$url->port(IO::Socket::INET->new(Listen => 5, LocalAddr => "127.0.0.1")->sockport);
my $daemon = Mojo::Server::Daemon->new(app => app(), listen => [$url]);
capture { $daemon->start };

ok !$INC{'AnyEvent.pm'}, 'did not load AnyEvent';
diag "AnyEvent.pm = $INC{'AnyEvent.pm'}" if $INC{'AnyEvent.pm'};

is(scalar Test::Script::Async::_detect(), 'mojo', '_detect = mojo');

script_runs(['corpus/mojoclient.pl',$url->port])
  ->exit_is(22)
  ->out_like(qr{Platypus Man})
  ->note;

package
  My::Log;

use Test2::Bundle::Extended;
use base qw( Mojo::Log );

sub append
{
  my($self, $message) = @_;
  note "log: $message";
}
