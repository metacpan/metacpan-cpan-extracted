package Testing::Result::Find;


use Test::Roo::Role;
with 'Testing::Result';

test 'search type' => sub {
  my ($self) = @_;
  cmp_ok $self->result_obj->message, 'eq', 'accurate',
    'message ok';
  cmp_ok $self->result_obj->search_type, 'eq', 'accurate',
    'search_type ok';
};

test 'list operations' => sub {
  my ($self) = @_;
  my $res = $self->result_obj;

  cmp_ok $res->count, '==', 2, 'count';
  cmp_ok $res->list,  '==', 2, 'scalar list';
  cmp_ok $res->as_array->count, '==', 2, 'as_array';
  my $itr = $res->iter;
  my $cnt = 0;
  while (my $v = $itr->()) {
    $cnt++;
    isa_ok $v, 'Weather::OpenWeatherMap::Result::Current'
  }
  cmp_ok $cnt, '==', 2, 'iter';
  $itr = $res->iter(2);
  cmp_ok @{[$itr->()]}, '==', '2', 'iter($n)';
};

test 'list items' => sub {
  my ($self) = @_;
  my ($first, $second) = $self->result_obj->list;

  cmp_ok $first->dt->epoch, '==', 1400106519,
    'first dt ok';
  cmp_ok $second->dt->epoch, '==', 1400106593,
    'second dt ok';

  cmp_ok $first->name, 'eq', 'London',
    'first name ok';
  cmp_ok $second->name, 'eq', 'London',
    'second name ok';

  cmp_ok $first->country, 'eq', 'GB',
    'first country ok';
  cmp_ok $second->country, 'eq', 'CA',
  ## FIXME document that 'country' is er, maybe not a country

  ## FIXME expanded tests
};

1;
