use strict;
use warnings;
use Test::More;
use Test::Mojo;
use utf8;
use Data::Dumper;
use Mojo::IOLoop;
use WWW::Crawler::Mojo;

use Test::More tests => 30;

use File::Basename 'dirname';
local $ENV{MOJO_HOME} = dirname(__FILE__);

{

  package MockServer;
  use Mojo::Base 'Mojolicious';

  sub startup {
    my $self = shift;
    unshift @{$self->static->paths}, $self->home->rel_file('public');
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
$bot->enqueue(WWW::Crawler::Mojo::resolve_href($base, '/index.html'));

my %urls;
my %contexts;

$bot->on(
  'res' => sub {
    my ($bot, $scrape, $job, $res) = @_;
    $urls{$job->url} = $job;
    return unless $res->code == 200;
    for my $job ($scrape->()) {
      $bot->enqueue($job);
      $contexts{$job} = $job->context;
    }
  }
);

$bot->init;

Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

is((scalar keys %urls), 10, 'right length');

my $q;
$q = $urls{WWW::Crawler::Mojo::resolve_href($base, '/index.html')};
is $q->depth,    0;
is $q->referrer, undef;
is $contexts{$q}, undef;
$q = $urls{WWW::Crawler::Mojo::resolve_href($base, '/js/js1.js')};
is $q->depth, 1;
is ref $contexts{$q}, 'Mojo::DOM';
is $contexts{$q},
  qq{<script src="./js/js1.js" type="text/javascript"></script>};
$q = $urls{WWW::Crawler::Mojo::resolve_href($base, '/css/css1.css')};
is $q->depth, 1;
is ref $contexts{$q}, 'Mojo::DOM';
is $contexts{$q},
  qq{<link href="./css/css1.css" rel="stylesheet" type="text/css">};
my $parent2 = $q;
$q = $urls{WWW::Crawler::Mojo::resolve_href($base, '/img/png1.png')};
is $q->depth, 1;
is ref $contexts{$q}, 'Mojo::DOM';
is $contexts{$q}, qq{<img alt="png1" src="./img/png1.png">};
$q = $urls{WWW::Crawler::Mojo::resolve_href($base, '/img/png2.png')};
is $q->depth, 2;
is ref $contexts{$q}, 'Mojo::URL';
is $contexts{$q}, qq{http://127.0.0.1:$port/css/css1.css};
$q = $urls{WWW::Crawler::Mojo::resolve_href($base, '/img/png3.png')};
is $q->depth, 1;
is ref $contexts{$q}, 'Mojo::DOM';
like $contexts{$q},
  qr{<div style="background-image:url\(\./img/png3.png\)">.+</div>}s;
$q = $urls{WWW::Crawler::Mojo::resolve_href($base, '/space.txt')};
is $q->depth, 1;
is ref $contexts{$q}, 'Mojo::DOM';
like $contexts{$q}, qr{<a href=" ./space.txt ">foo</a>}s;
$q = $urls{WWW::Crawler::Mojo::resolve_href($base, '/form_receptor1')};
is $q->url,   "http://127.0.0.1:$port/form_receptor1";
is $q->depth, 1;
is ref $contexts{$q}, 'Mojo::DOM';
like $contexts{$q}, qr{<form action="/form_receptor1" method="post">.+}s;
$q = $urls{
  WWW::Crawler::Mojo::resolve_href(
    $base, '/form_receptor2?a=b&query2=default'
  )
};
is $q->url,   "http://127.0.0.1:$port/form_receptor2?a=b&query2=default";
is $q->depth, 1;
is ref $contexts{$q}, 'Mojo::DOM';
like $contexts{$q}, qr{<form action="/form_receptor2\?a=b" method="get">.+}s;

$base = Mojo::URL->new("http://127.0.0.1:$port");
$bot  = WWW::Crawler::Mojo->new;
$bot->ua->request_timeout(0.1);
$bot->enqueue(WWW::Crawler::Mojo::resolve_href($base, '/'));

# It's useless test for timeout
#my $timeout;
#$bot->on('error' => sub { $timeout = 1 });
#$bot->init;
#Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
#is $timeout, 1, 'error event fired';

__END__
