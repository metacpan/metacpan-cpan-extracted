use strictures 1;
use Test::More 0.88;
use Plack::Test;
use HTTP::Request::Common qw(GET POST);

{
  package t::Web::Simple::ResponseFilter;
  use Web::Simple;
  sub dispatch_request {
    my $self = shift;
    sub (.html) {
      response_filter {
        return [
          200,
          [ 'Content-Type' => 'text/html' ], 
          [ shift->{name} ],
        ];
      }
    },
    sub (GET + /index) {
      bless {name=>'john'}, 'CrazyHotWildWet';
    },
  }
}

ok my $app = t::Web::Simple::ResponseFilter->new->to_psgi_app,
  'Got a plack app';

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/index.html");
    like $res->content, qr/john/,
      'Got Expected Content';
};

done_testing; 
