# app.psgi
use Web::Dispatcher::Simple;
my $app = router {
  get '/api' => sub {
      my $req = shift;
      my $res = $req->new_response(200);
      $res->body('Hello world');
      $res;
  },
  post '/comment/{id}' => sub {
    my ($req, $args)  = @_;
    my $id = $args->{id};
    my $res = $req->new_response(200);
    $res;
  }
};

