use Mojo::Base -strict;

BEGIN {
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}

use File::Basename 'dirname';
use File::Spec;
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '../extlib';
use lib join '/', File::Spec->splitdir(dirname(__FILE__)), '../lib';
use Mojo::IOLoop;
use Mojo::URL;
use WWW::Crawler::Mojo::UserAgent;
use Test::More;
use Test::Mojo;
use Mojo::Promise;

use Test::More tests => 46;

sub host_key { WWW::Crawler::Mojo::UserAgent::_host_key(@_) }

is host_key(Mojo::URL->new('http://a/a')),       'http://a',       'right key';
is host_key(Mojo::URL->new('http://a:80/a')),    'http://a',       'right key';
is host_key(Mojo::URL->new('http://a:8080/a')),  'http://a:8080',  'right key';
is host_key(Mojo::URL->new('http://a:443/a')),   'http://a:443',   'right key';
is host_key(Mojo::URL->new('https://a/a')),      'https://a',      'right key';
is host_key(Mojo::URL->new('https://a:443/a')),  'https://a',      'right key';
is host_key(Mojo::URL->new('https://a:1443/a')), 'https://a:1443', 'right key';
is host_key(Mojo::URL->new('https://a:80/a')),   'https://a:80',   'right key';
is host_key(Mojo::URL->new('ftp://a/a')),        undef,            'right key';
is host_key(Mojo::URL->new('/a')),               undef,            'right key';

{
  my $ua = WWW::Crawler::Mojo::UserAgent->new;

  my $uri1 = Mojo::URL->new('http://example.com/');
  my $uri2 = Mojo::URL->new('http://example.com:80/');
  my $uri3 = Mojo::URL->new('https://example.com/');
  my $uri4 = Mojo::URL->new('https://example.com:8080/');
  my $uri5 = Mojo::URL->new('http://☃.net');
  my $uri6 = Mojo::URL->new('http://xn--n3h.net');

  is $ua->active_host($uri1, 1), 1, 'right result';
  is $ua->active_host($uri1, 1), 2, 'right result';
  is $ua->active_host($uri1, 1), 3, 'right result';
  is $ua->active_host($uri2, 1), 4, 'right result';
  is $ua->active_host($uri3, 1), 1, 'right result';
  is $ua->active_host($uri3, 1), 2, 'right result';
  is $ua->active_host($uri4, 1), 1, 'right result';
  is $ua->active_host($uri4, 1), 2, 'right result';
  is $ua->active_host($uri5, 1), 1, 'right result';
  is $ua->active_host($uri6, 1), 2, 'right result';
  is $ua->active_conn, 10, 'right result';
  is $ua->active_host($uri1, -1), 3, 'right result';
  is $ua->active_host($uri1, -1), 2, 'right result';
  is $ua->active_host($uri2, -1), 1, 'right result';
  is $ua->active_host($uri1, -1), 0, 'right result';
  is $ua->active_host($uri3, -1), 1, 'right result';
  is $ua->active_host($uri3, -1), 0, 'right result';
  is $ua->active_host($uri4, -1), 1, 'right result';
  is $ua->active_host($uri4, -1), 0, 'right result';
  is $ua->active_host($uri5, -1), 1, 'right result';
  is $ua->active_host($uri6, -1), 0, 'right result';
  is $ua->active_conn, 0, 'right result';
}

my $ua = WWW::Crawler::Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);

{
  my $id1 = Mojo::IOLoop->server(
    {address => '127.0.0.1'},
    sub {
      my ($loop, $stream) = @_;
      $stream->on(
        read => sub {
          my ($stream, $chunk) = @_;
          like $chunk, qr{Authorization: Basic YTpi},
            'right Authorization header';
          $stream->write(
                "HTTP/1.1 200 OK\x0d\x0a"
              . "Content-Type: text/html\x0d\x0a\x0d\x0a",
          );
          $stream->close_gracefully;
        }
      );
    }
  );

  my $port = Mojo::IOLoop->acceptor($id1)->handle->sockport;

  $ua->credentials("http://127.0.0.1:$port" => "a:b");
  $ua->get("http://127.0.0.1:$port/file1");

  my $id2 = Mojo::IOLoop->server(
    {address => '127.0.0.1'},
    sub {
      my ($loop, $stream) = @_;
      $stream->on(
        read => sub {
          my ($stream, $chunk) = @_;
          unlike $chunk, qr{Authorization: Basic YTpi},
            'right Authorization header';
          $stream->write(
                "HTTP/1.1 200 OK\x0d\x0a"
              . "Content-Type: text/html\x0d\x0a\x0d\x0a",
          );
          $stream->close_gracefully;
        }
      );
    }
  );

  my $port2 = Mojo::IOLoop->acceptor($id2)->handle->sockport;

  $ua->get("http://127.0.0.1:$port2/file2");
  $ua->get("http://127.0.0.1:$port/file3");

  my $id3 = Mojo::IOLoop->server(
    {address => '127.0.0.1'},
    sub {
      my ($loop, $stream) = @_;
      $stream->on(
        read => sub {
          my ($stream, $chunk) = @_;
          like $chunk, qr{Authorization: Basic YTpi},
            'right Authorization header';
          $stream->write(
                "HTTP/1.1 200 OK\x0d\x0a"
              . "Content-Type: text/html\x0d\x0a\x0d\x0a",
          );
          $stream->close_gracefully;
        }
      );
    }
  );

  my $port3 = Mojo::IOLoop->acceptor($id3)->handle->sockport;

  my $url = Mojo::URL->new("http://127.0.0.1:$port3/file2")->userinfo('a:b');
  $ua->get($url);
  $ua->get($url);
}

$ua = WWW::Crawler::Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);

{
  my $id1 = Mojo::IOLoop->server(
    {address => '127.0.0.1'},
    sub {
      my ($loop, $stream) = @_;
      $stream->on(
        read => sub {
          my ($stream, $chunk) = @_;
          like $chunk, qr{Authorization: Basic Yjpj},
            'right Authorization header';
          $stream->write(
                "HTTP/1.1 200 OK\x0d\x0a"
              . "Content-Length: 0\x0d\x0a\x0d\x0a"
              . "Content-Type: text/html\x0d\x0a\x0d\x0a",
          );
          $stream->close_gracefully;
        }
      );
    }
  );

  my $port1 = Mojo::IOLoop->acceptor($id1)->handle->sockport;

  my $id2 = Mojo::IOLoop->server(
    {address => '127.0.0.1'},
    sub {
      my ($loop, $stream) = @_;
      $stream->on(
        read => sub {
          my ($stream, $chunk) = @_;
          like $chunk, qr{Authorization: Basic YTpi},
            'right Authorization header';
          $stream->write(
                "HTTP/1.1 302 Found\x0d\x0a"
              . "Location: http://127.0.0.1:$port1\x0d\x0a\x0d\x0a",
          );
          $stream->close_gracefully;
        }
      );
    }
  );

  my $port2 = Mojo::IOLoop->acceptor($id2)->handle->sockport;

  $ua->max_redirects(1);
  $ua->credentials(
    "http://127.0.0.1:$port1" => "b:c",
    "http://127.0.0.1:$port2" => "a:b",
  );
  my $sum   = 0;
  my @promises;
  for (1 .. 2) {
    push @promises, (my $p = Mojo::Promise->new);
    $ua->get(
      "http://127.0.0.1:$port2/",
      sub {
        $sum += $ua->active_host("http://127.0.0.1:$port1");
        $p->resolve;
      }
    );
  }
  is $ua->active_host("http://127.0.0.1:$port1"), 0, 'right value';
  is $ua->active_host("http://127.0.0.1:$port2"), 2, 'right value';
  Mojo::Promise->all(@promises)->then(sub {
    is $ua->active_host("http://127.0.0.1:$port1"), 0, 'right value';
    is $ua->active_host("http://127.0.0.1:$port2"), 0, 'right value';
    is $sum, 1;
  })->wait;
}
