use Mojo::Base -strict;
use Mojo::File 'path';
use Test::More;
use Test::Mojo;

my $home = path();
$home = path($home->dirname) if $home->basename eq 'blib';
$ENV{MOJO_CONFIG} = $home->child(qw(t log.conf))->to_string;
plan skip_all => "MOJO_CONFIG=$ENV{MOJO_CONFIG}" unless -r $ENV{MOJO_CONFIG};

my $log_file = $home->child(qw(t log.log))->to_string;

$ENV{MOJO_LOG_LEVEL} = 'debug';
unlink $log_file;
my $t = Test::Mojo->new('Toadfarm');
my %log;

$t->app->routes->get(
  '/with-request-base' => sub {
    my $c    = shift;
    my $base = $c->req->param('X-Request-Base') || '';

    $c->req->url->base(Mojo::URL->new($base)) if $base;
    $c->render(text => $base);
  }
);

$t->app->routes->get(
  '/with/identity' => sub {
    my $c = shift;
    $c->tx->req->env->{identity} = 'user1';
    $c->render(text => '123');
  }
);

$t->app->routes->get(
  '/stream/timeout' => sub {
    my $c = shift->render_later;
    Mojo::IOLoop->stream($c->tx->connection)->timeout(0.01);
  }
);

$t->app->routes->get('/stream/close' => sub { shift->render_later });

$t->get_ok('/with/identity')->status_is(200);
$t->get_ok($t->tx->req->url->to_abs->userinfo('secret:user')->path('/yikes'))->status_is(404);
$t->get_ok('/with-request-base?X-Request-Base=http://thorsen.pm/prefix/')->status_is(200)
  ->content_is('http://thorsen.pm/prefix/');

{
  local $TODO = 'Not sure how to get this to fail and still be ok';
  $t->ua->once(
    start => sub {
      my ($ua, $tx) = @_;
      Mojo::IOLoop->timer(
        0.02 => sub {
          Mojo::IOLoop->stream($tx->connection)->close;
        }
      );
    }
  );
  $t->get_ok('/stream/close');
  $t->get_ok('/stream/timeout');
}

ok -e $log_file, 'log file was created';
ok -s $log_file > 400, 'log file was written to';

open my $FH, '<', $log_file;
while (<$FH>) {
  diag "$.: $_" if $ENV{HARNESS_IS_VERBOSE};

  # 1: [2022-05-02 08:00:47.43058] [87507] [info] Loading plugin AccessLog
  # 2: [2022-05-02 08:00:47.43343] [87507] [info] [cru53-eNVpKN] user1 GET http://127.0.0.1:50575/with/identity 200 0.0007s
  # 3: [2022-05-02 08:00:47.44021] [87507] [info] [r7SWdN-hAcNU] 127.0.0.1 GET http://127.0.0.1:50575/yikes 404 0.0062s
  # 4: [2022-05-02 08:00:47.44136] [87507] [info] [39MZ7FvDelBV] 127.0.0.1 GET http://thorsen.pm/prefix/with-request-base?X-Request-Base=http%3A%2F%2Fthorsen.pm%2Fprefix%2F 200 0.0004s
  # 5: [2022-05-02 08:00:47.48140] [87507] [info] [AMiOzHurhgEo] 127.0.0.1 GET http://127.0.0.1:50575/stream/timeout 504 0.0129s

  $log{without_identity} = $_ if m!info.*?GET http://[\w\.]+:\d+/yikes 404 [\d.]+s$!s;
  $log{with_identity}    = $_ if m!info.*?GET http://[\w\.]+:\d+/with/identity 200 [\d.]+s$!s;
  $log{with_prefix}      = $_ if m!info.*X-Request-Base!s;
  $log{with_close}       = $_ if m!/close\s\d+!s;
  $log{with_timeout}     = $_ if m!/timeout.*504!s;
}

like $log{with_identity},    qr{\buser1\b.*identity}s,                         'got access log line with identity';
like $log{without_identity}, qr{GET.*yikes}s,                                  'got access log line without userinfo';
like $log{with_prefix},      qr{http://thorsen\.pm/prefix/with-request-base}s, 'got access log line base url prefix';
like $log{with_timeout},     qr{GET.*/timeout\s504\s}s,                        'got timeout';
ok !$log{with_close}, 'do not log when client close' or diag $log{with_close};

unlink $log_file unless $ENV{KEEP_LOG_FILE};
done_testing;
