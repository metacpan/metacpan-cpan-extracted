use strict;
use warnings FATAL => 'all';

use Test::More 0.88;

{
  package BazRole;
  use Web::Simple::Role;

  around dispatch_request => sub {
    my ($orig, $self) = @_;
    return (
      $self->$orig,
      sub (GET + /baz) {
        [ 200,
          [ "Content-type" => "text/plain" ],
          [ 'baz' ],
        ]
      }
    );
  };
}
{
  package FooBar;
  use Web::Simple;
  with 'BazRole';
  sub dispatch_request {
    sub (GET + /foo) {
      [ 200,
        [ "Content-type" => "text/plain" ],
        [ 'foo' ],
      ]
    },
    sub (GET + /bar) {
      [ 200,
        [ "Content-type" => "text/plain" ],
        [ 'bar' ],
      ]
    },
  }
}

use HTTP::Request::Common qw(GET POST);

my $app = FooBar->new;
sub run_request { $app->run_test_request(@_); }

for my $word (qw/ foo bar baz /) {
  my $get = run_request(GET "http://localhost/${word}");
  is($get->content, $word, "Dispatch $word");
}

done_testing;
