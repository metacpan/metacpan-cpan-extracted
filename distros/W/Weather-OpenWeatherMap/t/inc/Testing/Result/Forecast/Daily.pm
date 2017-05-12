package Testing::Result::Forecast::Daily;

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
  # id, name, country
  cmp_ok $self->result_obj->id, '==', 5089178, 
    'id';
  cmp_ok $self->result_obj->name, 'eq', 'Manchester',
    'name';
  cmp_ok $self->result_obj->country, 'eq', 'United States of America',
    'country';
};

test 'forecast list' => sub {
  my ($self) = @_;
  # count, list, as_array, iter
  cmp_ok $self->result_obj->count, '==', 3, 
    'count';

  my @list = $self->result_obj->list;
  cmp_ok @list, '==', 3,
    'list';
  isa_ok $_, 'Weather::OpenWeatherMap::Result::Forecast::Day'
    for @list;

  cmp_ok $self->result_obj->as_array->count, '==', 3,
    'as_array';

  # Also tests ->iter($n), ::Hourly tests default:
  my $iter = $self->result_obj->iter(3);
  my ($first, $second, $third) = $iter->();
  is_deeply 
    [ $first, $second, $third ], 
    [ @list ],
    'iter';
};



test 'dt' => sub {
  my ($self) = @_;
  # dt
  isa_ok $self->first->dt, 'DateTime';
  isa_ok $self->second->dt, 'DateTime';
  cmp_ok $self->first->dt->epoch, '==', 1397750400,
    'first dt';
  cmp_ok $self->second->dt->epoch, '==', 1397836800,
    'second dt';
};

test 'atmospheric' => sub {
  my ($self) = @_;
  # cloud_coverage, humidity, pressure
  cmp_ok $self->first->cloud_coverage, '==', 0,
    'first cloud_coverage';
  cmp_ok $self->second->cloud_coverage, '==', 80,
    'second cloud_coverage';

  cmp_ok $self->first->humidity, '==', 55,
    'first humidity';
  cmp_ok $self->second->humidity, '==', 74,
    'second humidity';

  cmp_ok $self->first->pressure, 'eq', '1049.98',
    'first pressure';
  cmp_ok $self->second->pressure, 'eq', '1041.91',
    'second pressure';
};

test 'conditions' => sub {
  my ($self) = @_;
  # conditions_{terse,verbose,code,icon}
  cmp_ok $self->first->conditions_terse, 'eq', 'Clear',
    'first conditions_terse';
  cmp_ok $self->second->conditions_terse, 'eq', 'Clouds',
    'second conditions_terse';

  cmp_ok $self->first->conditions_verbose, 'eq', 'sky is clear',
    'first conditions_verbose';
  cmp_ok $self->second->conditions_verbose, 'eq', 'broken clouds',
    'second conditions_verbose';

  cmp_ok $self->first->conditions_code, '==', 800,
    'first conditions_code';
  cmp_ok $self->second->conditions_code, '==', 803,
    'second conditions_code';

  cmp_ok $self->first->conditions_icon, 'eq', '01d',
    'first conditions_icon';
  cmp_ok $self->second->conditions_icon, 'eq', '04d',
    'second conditions_icon';
};

test 'temperatures' => sub {
  my ($self) = @_;
  # temp_min_f, temp_max_f, temp_min_c, temp_max_c
  cmp_ok $self->first->temp_min_f, '==', 30,
    'first temp_min_f';
  cmp_ok $self->second->temp_min_f, '==', 29,
    'second temp_min_f';

  cmp_ok $self->first->temp_max_f, '==', 40,
    'first temp_max_f';
  cmp_ok $self->second->temp_max_f, '==', 40,
    'second temp_max_f';

  cmp_ok $self->first->temp_min_c, '==', -1,
    'first temp_min_c';
  cmp_ok $self->second->temp_min_c, '==', -1,
    'second temp_min_c';

  cmp_ok $self->first->temp_max_c, '==', 4,
    'first temp_max_c';
  cmp_ok $self->second->temp_max_c, '==', 4,
    'second temp_max_c';

  my $temp_obj = $self->first->temp;
  isa_ok $temp_obj, 'Weather::OpenWeatherMap::Result::Forecast::Day::Temps';
  cmp_ok $temp_obj->min,   'eq', '30.67', 'temp->min';
  cmp_ok $temp_obj->max,   'eq', '40.28', 'temp->max';
  cmp_ok $temp_obj->morn,  'eq', '40.28', 'temp->morn';
  cmp_ok $temp_obj->eve,   'eq', '38.98', 'temp->eve';
  cmp_ok $temp_obj->night, 'eq', '30.67', 'temp->night';
  cmp_ok $temp_obj->day,   'eq', '40.28', 'temp->day';
};

test 'wind' => sub {
  my ($self) = @_;
  # wind_speed_{mph,kph}, wind_direction[_degrees]
  cmp_ok $self->first->wind_speed_mph, '==', 8,
    'first wind_speed_mph';
  cmp_ok $self->second->wind_speed_mph, '==', 7,
    'second wind_speed_mph';
  cmp_ok $self->first->wind_speed_kph, '==', 12,
    'first wind_speed_kph';

  cmp_ok $self->first->wind_direction, 'eq', 'E',
    'first wind_direction';
  cmp_ok $self->second->wind_direction, 'eq', 'E',
    'second wind_direction';

  cmp_ok $self->first->wind_direction_degrees, '==', 82,
    'first wind_direction_degrees';
  cmp_ok $self->second->wind_direction_degrees, '==', 79,
    'second wind_direction_degrees';
};


1;
