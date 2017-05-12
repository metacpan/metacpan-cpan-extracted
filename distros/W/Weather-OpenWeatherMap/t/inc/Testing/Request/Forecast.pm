package Testing::Request::Forecast;


use Test::Roo::Role;
with 'Testing::Request';

has rx_base => (
  is      => 'ro',
  builder => sub { 
    my ($self) = @_;
    '^http://api\.openweathermap\.org/data/2\.5/forecast/'
  },
);

test 'forecast default days' => sub {
  my ($self) = @_;
  cmp_ok $self->request_obj->days, '==', 7, 'default days';
};

test 'forecast request url by name' => sub {
  my ($self) = @_;
  my $re = $self->rx_base 
            . $self->request_obj->hourly ? '' : 'daily\?'
            . 'q=\S+&units='
            . $self->request_obj->_units
            . '&cnt='
            . $self->request_obj->days;
  cmp_ok $self->request_obj->url, '=~', $re, 'by name';
};

test 'forecast request url by coord' => sub {
  my ($self) = @_;
  my $re = $self->rx_base 
            . $self->request_obj_bycoord->hourly ? '' : 'daily\?'
            . 'lat=\S+&lon=\S+&units='
            . $self->request_obj_bycoord->_units
            . '&cnt='
            . $self->request_obj_bycoord->days;
  cmp_ok $self->request_obj_bycoord->url, '=~', $re, 'by coord';
};

test 'forecast request url by code' => sub {
  my ($self) = @_;
  my $re = $self->rx_base 
            . $self->request_obj_bycode->hourly ? '' : 'daily\?'
            . 'id=\d+&units='
            . $self->request_obj_bycode->_units
            . '&cnt='
            . $self->request_obj_bycode->days;
  cmp_ok $self->request_obj_bycode->url, '=~', $re, 'by code';
};

1;


