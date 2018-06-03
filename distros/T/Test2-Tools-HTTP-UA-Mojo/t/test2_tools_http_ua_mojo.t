use Test2::V0 -no_srand => 1;
use Test2::Tools::HTTP;
use Test::Mojo;
use Mojolicious::Lite;
use HTTP::Request::Common;

get '/foo' => sub {
  my($c) = @_;
  $c->render(text => "hello world\n");
};

get '/bar' => sub {
  my($c) = @_;
  $c->redirect_to('/bar/index.html');
};

get '/bar/index.html' => sub {
  my($c) = @_;
  $c->render(text => "index text\n");
};

my $t = Test::Mojo->new;
$t->ua->max_redirects(10);

app->log->unsubscribe('message');
app->log->on(message => sub {
  my($log, $level, @lines) = @_;
  note "[$level] $_" for @lines;
});

$t->get_ok('/foo')
  ->status_is(200)
  ->content_is("hello world\n");

http_ua($t->ua);

note "http_base_url = ", http_base_url;

isa_ok( http_ua, 'Mojo::UserAgent' );

http_request(
  GET('/foo'),
  http_response {
    http_code 200;
    http_content "hello world\n";
  }
);

http_tx->note;  

http_request(
  GET('/bar'),
  http_response {
    http_code 302;
    http_location '/bar/index.html';
  },
);

http_tx->note;

http_request(
  GET(http_tx->location),
  http_response {
    http_code 200;
    http_content "index text\n";
  },
);

http_tx->note;

http_request(
  [ GET('/bar'), follow_redirects => 1 ],
  http_response {
    http_code 200;
    http_content "index text\n";
  },
);

http_tx->note;

http_request(
  GET('/missing'),
  http_response {
    http_code 404;
  },
);

http_tx->note;

psgi_app_add 'http://my1.test' => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "App the first\n" ] ] };
psgi_app_add 'http://my2.test' => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ "App the second\n" ] ] };

http_request(
  GET('http://my1.test'),
  http_response {
    http_code 200;
    http_content "App the first\n";
  },
);

http_tx->note;

http_request(
  GET('http://my2.test'),
  http_response {
    http_code 200;
    http_content "App the second\n";
  },
);

http_tx->note;

done_testing

__DATA__

@@ not_found.html.ep
<html>
  <head>
    <title>Not Found</title>
  </head>
  <body>
    <p>Not Found</p>
  </body>
</html>
