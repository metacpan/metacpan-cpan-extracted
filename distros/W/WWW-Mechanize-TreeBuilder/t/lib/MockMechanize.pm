package # Hide from pause
  MockMechanize;

use strict;
use warnings;

use base 'Test::WWW::Mechanize';

sub _make_request {
  my ($self, $req) = @_;

  my ($res);

  if ($req->uri eq '/') {
   $res = HTTP::Response->new(200, 'OK', ['Content-Type' => 'text/html; charset=utf-8'], <<"EOF");
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
  <title>Hurrah \342\230\203!</title>
</head>
<body>
  <h1>It works</h1>
  <p>A para</p>
</body>
</html>
EOF
  } elsif ($req->uri eq '/plain') {
   $res =  HTTP::Response->new(200, 'OK', ['Content-Type' => 'text/plain'], "I'm plain text");
  } elsif ($req->uri eq '/image') {
   $res =  HTTP::Response->new(200, 'OK', ['Content-Type' => 'image/gif'], "I should be an image");
  }
 
  $res->request($req);
  $res->header( 'Content-Base'   => $req->uri,
                'Content-Length' => length $res->content,
                Status => 200,
                Date   => 'Tue, 04 Sep 2007 16:57:36 GMT' ); 
  return $res;
}

1;
