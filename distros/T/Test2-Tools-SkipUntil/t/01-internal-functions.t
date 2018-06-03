#!/usr/bin/perl
use strict;
use warnings;
use Test2::Bundle::More;
use Test2::Tools::Exception 'dies';
use Time::Piece;

use Test2::Tools::SkipUntil;

subtest 'parse_datetime' => sub {
  my $sub = \&Test2::Tools::SkipUntil::parse_datetime;

  ok my $tp = $sub->('2015-07-02T12:30:01'), 'parse datetime';
  is ref $tp, 'Time::Piece', 'datetime parsed into Time::Piece';

  is $tp->year, 2015, 'parsed year is 2015';
  is $tp->mon,  7,  'parsed month is 7';
  is $tp->mday, 2,  'parsed day is 2';
  is $tp->hour, 12,'parsed hour is 12';
  is $tp->min,  30, 'parsed min is 30';
  is $tp->sec,  1,  'parsed sec is 1';
  is $tp->tzoffset, 0, 'parsed datetime is UTC';

  ok $tp = $sub->('2016-11-28'), 'parse date';
  is ref $tp, 'Time::Piece', 'date parsed into Time::Piece';
  is $tp->year, 2016, 'parsed year is 2016';
  is $tp->mon,  11,  'parsed month is 11';
  is $tp->mday, 28,  'parsed day is 28';
  is $tp->tzoffset, 0, 'parsed datetime is UTC';

  ok dies { $sub->(undef) },      'dies on undef';
  ok dies { $sub->() },           'dies on empty list';
  ok dies { $sub->('') },         'dies on empty string';
  ok dies { $sub->("1b") },       'dies on alphanumeric';
  ok dies { $sub->(1526157756) }, 'dies on epoch';
  ok dies { $sub->(1.5) },        'dies on decimal';
};

subtest 'apply_offset' => sub {
  my $sub = \&Test2::Tools::SkipUntil::apply_offset;
  my $tp = localtime();

  ok my $tp_local = $sub->($tp), 'returns a value';
  is ref $tp_local, 'Time::Piece', 'returns a Time::Piece object';

  my $offset = localtime()->tzoffset;
  ok $tp_local == $tp + $offset, 'correct offset applied to Time::Piece object';
};

subtest 'check_skip_count' => sub {
  my $sub = \&Test2::Tools::SkipUntil::check_skip_count;

  ok $sub->(1),     '1 is ok';
  ok $sub->(59),    '59 is ok';
  ok $sub->(10000), '10000 is ok';

  ok dies { $sub->(undef) }, 'dies on undef';
  ok dies { $sub->() },      'dies on empty list';
  ok dies { $sub->('') },     'dies on empty string';
  ok dies { $sub->("1b") },  'dies on alphanumeric';
  ok dies { $sub->(-1) },    'dies on negative num';
  ok dies { $sub->(1.5) },   'dies on decimal';
};

subtest 'should_skip' => sub {
  my $sub = \&Test2::Tools::SkipUntil::should_skip;

  my $tp_past = Time::Piece->strptime('2005-07-24', '%Y-%m-%d');
  ok !$sub->($tp_past), 'don\'t skip for past date';

  my $tp_future = Time::Piece->strptime('2037-07-24', '%Y-%m-%d');
  ok my $tp_now =  $sub->($tp_future), 'do skip for future date';
};

subtest 'check_why' => sub {
  my $sub = \&Test2::Tools::SkipUntil::check_why;

  ok dies { $sub->(undef) }, 'dies on undef';
  ok dies { $sub->() },      'dies on empty list';
  ok dies { $sub->('') },    'dies on empty string';
  ok dies { $sub->([]) },    'dies on arrayref';
};
done_testing;
