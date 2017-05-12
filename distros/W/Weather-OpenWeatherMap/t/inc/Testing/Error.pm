package Testing::Error;

use Weather::OpenWeatherMap::Error;
use Weather::OpenWeatherMap::Request;

use Test::Roo::Role;

has error_obj => (
  is      => 'ro',
  builder => sub {
    my $req = Weather::OpenWeatherMap::Request->new_for(
      Current => 
        api_key   => 'abcd',
        location  => 'foo', 
        tag       => 'bar'
    );
    Weather::OpenWeatherMap::Error->new(
      request => $req,
      source  => 'http',
      status  => 'died badly',
    )
  },
);

test 'error attributes' => sub {
  my ($self) = @_;
  cmp_ok $self->error_obj->status, 'eq', 'died badly',
    'status';
  cmp_ok $self->error_obj->source, 'eq', 'http',
    'source';
  isa_ok $self->error_obj->request, 'Weather::OpenWeatherMap::Request';
};

test 'stringification' => sub {
  my ($self) = @_;
  cmp_ok $self->error_obj, 'eq', '(HTTP) died badly',
    'stringification';
};

test 'stack trace' => sub {
  my ($self) = @_;
  ok $self->error_obj->does('StackTrace::Auto'), 'does StackTrace::Auto';
};

1;
