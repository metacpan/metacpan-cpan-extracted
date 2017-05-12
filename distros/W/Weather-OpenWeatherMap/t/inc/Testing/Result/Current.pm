package Testing::Result::Current;

use Test::Roo::Role;
with 'Testing::Result';


test 'dt' => sub {
  my ($self) = @_;
  # dt
  isa_ok $self->result_obj->dt, 'DateTime';
  cmp_ok $self->result_obj->dt->epoch, '==', 1397768668,
    'dt';
};

test 'identifiers' => sub {
  my ($self) = @_;
  # id, name, country, station
  cmp_ok $self->result_obj->id, '==', 5089178, 
    'id';
  cmp_ok $self->result_obj->name, 'eq', 'Manchester', 
    'name';
  cmp_ok $self->result_obj->country, 'eq', 'United States of America',
    'country';
  cmp_ok $self->result_obj->station, 'eq', 'cmc stations',
    'station';
};

test 'lat long' => sub {
  my ($self) = @_;
  # latitude, longitude
  cmp_ok $self->result_obj->latitude, 'eq', '42.99',
    'latitude';
  cmp_ok $self->result_obj->longitude, 'eq', '-71.46',
    'longitude';
};

test 'temperatures' => sub {
  my ($self) = @_;
  # temp_f, temp_c
  cmp_ok $self->result_obj->temp_f, '==', 41,
    'temp_f';
  cmp_ok $self->result_obj->temp, '==', $self->result_obj->temp_f,
    'temp aliased to temp_f';
  cmp_ok $self->result_obj->temp_c, '==', 5,
    'temp_c';
};

test 'atmospheric' => sub {
  my ($self) = @_;
  # cloud_coverage, humidity, pressure
  cmp_ok $self->result_obj->cloud_coverage, '==', 8,
    'cloud_coverage';
  cmp_ok $self->result_obj->humidity, '==', 49,
    'humidity';
  cmp_ok $self->result_obj->pressure, '==', 1040,
    'pressure';
};

test 'sun rise and set' => sub {
  my ($self) = @_;
  # sunrise, sunset
  isa_ok $self->result_obj->sunrise, 'DateTime';
  isa_ok $self->result_obj->sunset,  'DateTime';
  cmp_ok $self->result_obj->sunrise->epoch, '==', 1397728770,
    'sunrise';
  cmp_ok $self->result_obj->sunset->epoch,  '==', 1397777462,
    'sunset';
};

test 'conditions' => sub {
  my ($self) = @_;
  # conditions_{terse,verbose,code,icon}
  cmp_ok $self->result_obj->conditions_terse, 'eq', 'Rain',
    'conditions_terse';
  cmp_ok $self->result_obj->conditions_verbose, 'eq', 'light rain',
    'conditions_verbose';
  cmp_ok $self->result_obj->conditions_code, '==', 500,
    'conditions_code';
  cmp_ok $self->result_obj->conditions_icon, 'eq', '10d',
    'conditions_icon';
};

test 'wind' => sub {
  my ($self) = @_;
  # wind_speed_{mph,kph}, wind_gust_{mph,kph}, wind_direction[_degrees]
  cmp_ok $self->result_obj->wind_speed_mph, '==', 2,
    'wind_speed_mph';
  cmp_ok $self->result_obj->wind_speed_kph, '==', 3,
    'wind_speed_kph';
  cmp_ok $self->result_obj->wind_gust_mph, '==', 6,
    'wind_gust_mph';
  cmp_ok $self->result_obj->wind_gust_kph, '==', 9,
    'wind_gust_kph';
  cmp_ok $self->result_obj->wind_direction_degrees, '==', 59,
    'wind_direction_degrees';
  cmp_ok $self->result_obj->wind_direction, 'eq', 'ENE',
    'wind_direction';
};


1;
