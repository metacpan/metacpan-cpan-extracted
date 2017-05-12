#!/usr/bin/perl -w

use strict;

use Test::More qw(no_plan);

BEGIN {
  use_ok('TidyView::Options');
};

require_ok('TidyView::Options');

can_ok('TidyView::Options', qw(
			       assembleOptions
			       build
			      )
      );

use Log::Log4perl qw(:levels get_logger);

Log::Log4perl->init_and_watch('bin/log.conf', 10);

my $logger = get_logger((caller(0))[3]);

# test _getCategoryType()

is(TidyView::Options->_getTypeCategory(),                 'checkbox', 'no type falls back to checkbox' );

is(TidyView::Options->_getTypeCategory(type => undef),    'checkbox', 'undef falls back to checkbox'   );

is(TidyView::Options->_getTypeCategory(type => '!'),      'checkbox', 'type of ! means checkbox'       );

is(TidyView::Options->_getTypeCategory(type => '=s'),     'string',   'type of =s means string entry'  );

is(TidyView::Options->_getTypeCategory(type => '=i'),     'integer',  'type of =i means spinbox'       );

is(TidyView::Options->_getTypeCategory(type => 'ARRAY'),  'list',     'type of array  means listbox'   );

my @die = ();

eval {
  local $SIG{__DIE__} = sub {push @die, @_};

  TidyView::Options->_getTypeCategory(type => 'UNKNOWN');
};

diag("dont worry - we expected that!");

is(@die, 1, 'expected we died'); # died

like(shift(@die), qr(^unknown entry type UNKNOWN at ), 'expected suicide note');

# test _mapRangeToList()

is(TidyView::Options->_mapRangeToList(), undef, 'no range returns no range');

is(TidyView::Options->_mapRangeToList(undef), undef, 'undefined range returns undefined range');

is(TidyView::Options->_mapRangeToList('SIMPLE'), 'SIMPLE', 'scalar range returns scalar range');

is_deeply(TidyView::Options->_mapRangeToList([]), [], 'empty range returns empty range');

is_deeply(TidyView::Options->_mapRangeToList([0]), [0], 'single range returns single range');

is_deeply(TidyView::Options->_mapRangeToList([0, 1, 2]), [0, 1, 2], 'overlong range returns overlong range');

is_deeply(TidyView::Options->_mapRangeToList([3, 1]), [3, 1], 'inverted range returns inverted range');

is_deeply(TidyView::Options->_mapRangeToList(['a', 'c']), ['a', 'c'], 'unmappable range returns unmappable range');

# the one we really want
is_deeply(TidyView::Options->_mapRangeToList([1, 5]), [1, 2, 3, 4, 5], 'mappable range returns mapped range');

# test _differentToDefault

is(TidyView::Options->_differentToDefault(), 1, 'nothing is defined to be different to the default');

is(TidyView::Options->_differentToDefault(name => undef), 1, 'nothing is defined to be different to the default');

is(TidyView::Options->_differentToDefault(name => undef), 1, 'nothing is defined to be different to the default');

is(TidyView::Options->_differentToDefault(name => 'UNKNOWN'), 1, 'invalid entry has no default, hence is different');

is(TidyView::Options->_differentToDefault(name => 'perl-syntax-check-flags'), 1, 'undefined current value means is diff to default');

is(TidyView::Options->_differentToDefault(name         => 'perl-syntax-check-flags',
					  currentValue => undef), 1, 'undefined current value means is diff to default');

is(TidyView::Options->_differentToDefault(name         => 'perl-syntax-check-flags',
					  currentValue => 'different'), 1, 'current value diff to default');

is(TidyView::Options->_differentToDefault(name         => 'perl-syntax-check-flags',
					  currentValue => '-c -T'), '', 'current value same as default');
# test assemble options

is(TidyView::Options->assembleOptions(), '', 'assemble before anything is set');

# test assemble unsupported options

TidyView::Options->storeUnsupportedOptions(rawOptions => {
							  'standard-output' => 1, # unsupported
							  'check-syntax'    => 1, # supported
							 });

is(TidyView::Options->assembleUnsupportedOptions(), '--standard-output  ', 'assemble unsupported options');

TidyView::Options->clearUnsupportedOptions();

is(TidyView::Options->assembleUnsupportedOptions(), '', 'assemble unsupported options');

