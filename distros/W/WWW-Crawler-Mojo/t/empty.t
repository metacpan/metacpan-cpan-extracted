use strict;
use warnings;
use Test::More;
use Test::Mojo;
use utf8;
use Data::Dumper;
use Mojo::IOLoop;
use WWW::Crawler::Mojo;
use WWW::Crawler::Mojo::ScraperUtil qw{resolve_href};

use Test::More tests => 1;

use File::Basename 'dirname';
local $ENV{MOJO_HOME} = dirname(__FILE__);

{

  package MockServer;
  use Mojo::Base 'Mojolicious';

  sub startup {
    my $self = shift;
    unshift @{$self->static->paths}, $self->home->rel_file('public2');
  }
}

my $daemon = Mojo::Server::Daemon->new(
  app    => MockServer->new,
  ioloop => Mojo::IOLoop->singleton,
  silent => 1
);

$daemon->listen(['http://127.0.0.1'])->start;

my $port = Mojo::IOLoop->acceptor($daemon->acceptors->[0])->handle->sockport;
my $base = Mojo::URL->new("http://127.0.0.1:$port");
my $bot  = WWW::Crawler::Mojo->new;
$bot->enqueue(resolve_href($base, '/index.html'));

my %urls;

$bot->on(
  'res' => sub {
    my ($bot, $scrape, $job, $res) = @_;
    $scrape->();
    $bot->enqueue($_) for ($scrape->());
    $urls{$job->url} = $job;
  }
);

$bot->init;

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

is((scalar keys %urls), 3, 'right length');

__END__
