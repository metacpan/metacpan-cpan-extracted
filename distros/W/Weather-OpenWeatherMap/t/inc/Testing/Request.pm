package Testing::Request;

use Types::Standard -all;
use Test::Roo::Role;

requires 'request_obj', 
         'request_obj_bycoord',
         'request_obj_bycode';


test 'accessors' => sub {
  my ($self) = @_;
  my $req = $self->request_obj;
  isa_ok $req, 'Weather::OpenWeatherMap::Request';
  ok $req->api_key,  'api_key';
  ok $req->location, 'location';
  ok $req->tag,      'tag';
  ok is_StrictNum $req->ts, 'ts';
  like $req->url,
       qr{^http://api.openweathermap.org/},
       'url';
};

test 'http request' => sub {
  my ($self) = @_;
  my $req = $self->request_obj;
  isa_ok $req->http_request, 'HTTP::Request';
  cmp_ok $req->http_request->header('x-api-key'),
    'eq', $req->api_key,
    'request header';
};


1;
