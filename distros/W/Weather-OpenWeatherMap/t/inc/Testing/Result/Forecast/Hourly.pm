package Testing::Result::Forecast::Hourly;

use Test::Roo::Role;
with 'Testing::Result';

has first => (
  lazy    => 1,
  is      => 'ro',
  writer  => 'set_first',
  builder => sub { shift->result_obj->as_array->get(0) },
);

has second => (
  lazy    => 1,
  is      => 'ro',
  writer  => 'set_second',
  builder => sub { shift->result_obj->as_array->get(1) },
);

test 'storable' => sub {
  my ($self) = @_;
  can_ok $self->result_obj, 'freeze';
};

test 'identifiers' => sub {
  my ($self) = @_;

  ok $self->request_obj->hourly,
    'Request has hourly => 1';
  ok $self->result_obj->hourly,
    'Result has hourly => 1';

  cmp_ok $self->result_obj->id, '==', 524901,
    'id';
  cmp_ok $self->result_obj->name, 'eq', 'Moscow',
    'name';
  cmp_ok $self->result_obj->country, 'eq', 'RU',
    'country';
};

test 'forecast list' => sub {
  my ($self) = @_;

  cmp_ok $self->result_obj->count, '==', 40,
    'count';
  my @list = $self->result_obj->list;
  cmp_ok @list, '==', 40,
    'list';
  isa_ok $_, 'Weather::OpenWeatherMap::Result::Forecast::Hour'
    for @list;
  cmp_ok $self->result_obj->as_array->count, '==', 40,
    'as_array';

  # Also tests default ->iter(), ::Daily tests ->iter($n):
  my $iter = $self->result_obj->iter;
  my ($first, $second, $third) = map $iter->(), 1 .. 3;
  is_deeply
    [ $first, $second, $third ],
    [ @list[0..2] ],
    'iter';
};

test 'dt' => sub {
  my ($self) = @_;

  isa_ok $self->first->dt, 'DateTime';
  isa_ok $self->second->dt, 'DateTime';
  cmp_ok $self->first->dt->epoch, '==', 1451077200,
    'first dt';
  cmp_ok $self->second->dt->epoch, '==', 1451088000,
    'second dt';

  cmp_ok $self->first->dt_txt, 'eq', '2015-12-25 21:00:00',
    'first dt_txt';
  cmp_ok $self->second->dt_txt, 'eq', '2015-12-26 00:00:00',
    'second dt_txt';
};

test 'atmospheric' => sub {
  my ($self) = @_;

  cmp_ok $self->first->cloud_coverage, '==', 92,
    'cloud_coverage';
  cmp_ok $self->first->pressure, 'eq', '1002.83',
    'pressure';
  cmp_ok $self->first->humidity, '==', 91,
    'humidity';
};

test 'conditions' => sub {
  my ($self) = @_;

  cmp_ok $self->first->temp_f, '==', 33,
    'temp_f';
  cmp_ok $self->first->temp, '==', $self->first->temp_f,
    'temp aliased to temp_f';
  cmp_ok $self->first->temp_c, '==', 0,
    'temp_c';

  cmp_ok $self->first->conditions_terse, 'eq', 'Snow',
    'conditions_terse';
  cmp_ok $self->first->conditions_verbose, 'eq', 'snow',
    'conditions_verbose';
  cmp_ok $self->first->conditions_code, 'eq', '601',
    'conditions_code';
  cmp_ok $self->first->conditions_icon, 'eq', '13n',
    'conditions_icon';
};

test 'precipitation' => sub {
  my ($self) = @_;
  cmp_ok $self->first->snow, 'eq', '2.1',
    'snow ok';
  cmp_ok $self->first->rain, '==', 0,
    'rain (default) ok';
  cmp_ok $self->second->rain, 'eq', '0.1',
    'rain (non-default) ok';
};

test 'wind' => sub {
  my ($self) = @_;

  cmp_ok $self->first->wind_speed_mph, '==', 11,
    'wind_speed_mph';
  cmp_ok $self->first->wind_speed_kph, '==', 17,
    'wind_speed_kph';
  cmp_ok $self->first->wind_direction, 'eq', 'WSW',
    'wind_direction';
  cmp_ok $self->first->wind_direction_degrees, '==', 241,
    'wind_direction_degrees';
};

1;
