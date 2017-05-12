package Testing::Request::Current;


use Test::Roo::Role;
with 'Testing::Request';

has rx_base => (
  is      => 'ro',
  builder => sub { '^http://api\.openweathermap\.org/data/2\.5/weather\?' },
);

test 'current request url by name' => sub {
  my ($self) = @_;
  my $re = $self->rx_base . 'q=(?:\S+)&units=imperial';
  cmp_ok $self->request_obj->url, '=~', $re, 'url (by name)'
};

test 'current request url by coord' => sub {
  my ($self) = @_;
  my $re = $self->rx_base . 'lat=(?:\d+)&lon=(?:\d+)&units=imperial';
  cmp_ok $self->request_obj_bycoord->url, '=~', $re, 'url (by coord)';
};

test 'current request url by code' => sub {
  my ($self) = @_;
  my $re = $self->rx_base . 'id=(?:\d+)&units=imperial';
  cmp_ok $self->request_obj_bycode->url, '=~', $re, 'url (by code)';
};


1;
