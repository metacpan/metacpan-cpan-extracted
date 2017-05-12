use strict;
use warnings FATAL => 'all';

use Test::More qw(no_plan);

require_ok 'examples/bloggery/bloggery.cgi';

__END__
#use Test::More (
#  eval { require HTTP::Request::AsCGI }
#    ? 'no_plan'
##    : (skip_all => 'No HTTP::Request::AsCGI')
#);
use HTTP::Request::AsCGI;  

use HTTP::Request::Common qw(GET POST);

require 'examples/bloggery/bloggery.cgi';

my $app = Bloggery->new(
  { config => { posts_dir => 'examples/bloggery/posts' } }
);

sub run_request {
  my $request = shift;
  my $c = HTTP::Request::AsCGI->new($request, SCRIPT_NAME=> $0)->setup;
  $app->run;
  $c->restore;
  return $c->response;
}

my $res;

warn run_request(GET 'http://localhost/index.html')->as_string;

warn run_request(GET 'http://localhost/')->as_string;

warn run_request(GET 'http://localhost/One-Post.html')->as_string;

warn run_request(GET 'http://localhost/Not-There.html')->as_string;

warn run_request(POST 'http://localhost/One-Post.html')->as_string;
