package Testing::Request::Find;

use Scalar::Util 'blessed';

use Test::Roo::Role;
with 'Testing::Request';

has request_obj_bycode => (
  is      => 'ro',
  builder => sub { 1 },
);

has rx_base => (
  is      => 'ro',
  builder => sub {
    '^http://api\.openweathermap\.org/data/2\.5/find\?'
  },
);


test 'find request url by name' => sub {
  my ($self) = @_;
  my $re = $self->rx_base 
            . 'q=\S+&units='
            . $self->request_obj->_units
            . '&type='
            . $self->request_obj->type
            . '&cnt='
            . $self->request_obj->max;
  cmp_ok $self->request_obj->url, '=~', $re, 'by name';
};

test 'find request url by coord' => sub {
  my ($self) = @_;
  my $re = $self->rx_base
            . 'lat=\S+&lon=\S+&units='
            . $self->request_obj_bycoord->_units
            . '&type='
            . $self->request_obj->type
            . '&cnt='
            . $self->request_obj_bycoord->max;
  cmp_ok $self->request_obj_bycoord->url, '=~', $re, 'by coord';
};

test 'find request by city code dies' => sub {
  my ($self) = @_;
  my $class = blessed $self->request_obj;
  my $obj;
  eval {;
    $obj = $class->new(
      api_key  => 'abcd',
      location => 1234,
    )
  };
  my $died = $@
    or fail "Find request on city code did not throw exception";
  isa_ok $died, 'Weather::OpenWeatherMap::Error';
  like "$died", qr/city code/, 'Find request on city code dies ok';
};


1;
