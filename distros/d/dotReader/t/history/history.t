#!/usr/bin/perl

# vim:ts=2:sw=2:et:sta:syntax=perl

use strict;
use warnings;

use Test::More (
  'no_plan'
  );

use constant {
  class => 'List::History',
};

BEGIN { use_ok('List::History') };

# check the alias definitions
ok(class->can('list'),              'list() accessor');
ok(class->can('get_list'),          'get_list() accessor');
ok((
  class->can('list') eq
  class->can('get_list')
  ),                                'alias list() to get_list()'
);
#ok(class->can('set_list'),          'set_list() mutator');

ok(class->can('current'),           'current() accessor');
ok(class->can('get_current'),       'get_current() accessor');
ok((not class->can('set_current')), 'no set_current() mutator');
ok((
  class->can('current') eq
  class->can('get_current')
  ),                                'alias current() to get_current()'
);

ok(class->can('current_pos'),       'current_pos() accessor');
ok(class->can('get_current_pos'),   'get_current_pos() accessor');
ok((
  class->can('current_pos') eq
  class->can('get_current_pos')
  ),                                'alias current_pos() to get_current_pos()'
);
ok(class->can('set_current_pos'),   'set_current_pos() mutator');

foreach my $group (
  [qw(f fore foreward)],
  [qw(b back backward)],
  ) {
  my (@alias) = @$group[0,1];
  my ($method) = $group->[2];
  foreach my $m (@$group) {
    ok(class->can($m),              "$m() accessor");
  }
  foreach my $al (@alias) {
    ok((
      class->can($al) eq
      class->can($method)
      ),                            "alias $al() to $method"
    );
  }
}

foreach my $method (qw(
  new
  add
  remember
  has_current
  has_next
  has_prev
  get_moment
  clear_future
  )) {
  ok(class->can($method),           "$method() method");
}

my %mspec = (
  day => 1,
  hour => 1,
  dog => 'fido',
  );
my $hist = List::History->new(moment_spec => \%mspec);
ok($hist,                           'constructor');
isa_ok($hist, class,                'isa '. class);

# we use this later
my $gen_class = "$hist"; $gen_class =~ s/.*=(.*)/$1-moment/;

{
  # check the generated moment class
  ok($gen_class->can('new'), 'can new');
  my $moment = $hist->moment(day => 1, hour => 2, dog => 'spike');
  isa_ok($moment, $gen_class);
  foreach my $key (keys(%mspec)) {
    ok($moment->can($key),       "can $key");
    ok($moment->can("get_$key"), "can get_$key");
    ok($moment->can("set_$key"), "can set_$key");
  }
  is($moment->get_day, 1, 'day');
  is($moment->day, 1, 'day');
  eval { $moment->set_day(2) };
  ok(! $@);
  is($moment->day, 2, 'day set');
}

{
my @list = $hist->get_list;
ok(@list == 0,                      'got empty list');
}
{
my $has = $hist->has_current;
ok((not $has),                      'no current moment at new');
}
{
my $has = $hist->has_prev;
ok((not $has),                      'no previous moment at new');
}
{
my $has = $hist->has_next;
ok((not $has),                      'no next moment at new');
}

# add a moment
my $moment1 = $hist->add();
isa_ok($moment1, $gen_class,        'made a moment');
{
my $has = $hist->has_current;
ok((not $has),                      'no current moment at add');
}
{
my $has = $hist->has_prev;
ok($has,                            'has previous at add');
}
{
my $has = $hist->has_next;
ok((not $has),                      'no next moment at add');
}

# remember a moment
my $moment2 = $hist->remember(scroll_pos => 7);
isa_ok($moment2, $gen_class,        'made a moment');
{
my $has = $hist->has_current;
ok($has,                            'has current moment at remember');
}
{
my $has = $hist->has_prev;
ok($has,                            'has previous at remember');
}
{
my $has = $hist->has_next;
ok((not $has),                      'no next moment at remember');
}

# go back
{
my $moment = $hist->back;
isa_ok($moment, $gen_class,         'retrieved a moment');
ok($moment eq $moment1,             'matches the original');
}

{
my $has = $hist->has_current;
ok($has,                            'has current moment at back');
}
{
my $has = $hist->has_prev;
ok((not $has),                      'no previous at back');
}
{
my $has = $hist->has_next;
ok($has,                            'has next moment at back');
}
{
my @list = $hist->get_list;
ok(@list == 2,                      'got 2-item list');
}
# XXX I'm considering making this a private method now
# $hist->clear_future;
# {
# my @list = $hist->get_list;
# ok(@list == 1,                      'got 1-item list');
# my $has = $hist->has_next;
# ok((not $has),                      'no next moment after clear_future');
# }
