#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';

# Regression test for GH#18: `use Test::Most import => [...]` died with
# "plan() doesn't understand import ARRAY(...)" because the pair fell
# through to plan() instead of being consumed as an export filter.
#
# `import => [...]` must be supplied as the first arg to actually exercise
# the regression — it's what gets handed to plan() and what plan() chokes on.
use Test::Most import => [qw( ok done_testing is blessed subtest )];

ok 1, 'ok was imported via the explicit list';
is 2, 2, 'is was imported via the explicit list';
ok defined( &main::blessed ),
    'symbols normally excluded by default may be imported when listed explicitly';
ok !defined( &main::eq_or_diff ),
    'symbols not in the import list are not exported';
ok !defined( &main::dies_ok ),
    'Test::Exception symbols not in the import list are not exported';
ok !defined( &main::cmp_deeply ),
    'Test::Deep symbols not in the import list are not exported';
ok !defined( &main::warning_is ),
    'Test::Warn symbols not in the import list are not exported';

subtest 'empty import list falls through to default exports' => sub {
    # This matches Test::Builder::Module and Exporter, both of which treat
    # an empty import list as "use defaults". Pre-0.39 Test::Most inherited
    # the same behaviour via `goto &Test::Builder::Module::import`, so we
    # preserve it here.
    package EmptyList;
    Test::Most->import( import => [] );
    main::ok( defined( &EmptyList::ok ),         'ok exported (default)' );
    main::ok( defined( &EmptyList::cmp_deeply ), 'cmp_deeply exported (default)' );
};

subtest 'fully excluded import list exports nothing' => sub {
    package AllExcluded;
    Test::Most->import( import => [qw( is )], '!is' );
    main::ok( !defined( &AllExcluded::is ), 'excluded symbol not exported' );
    main::ok( !defined( &AllExcluded::ok ), 'unrelated default not exported' );
};

subtest 'import list combined with plan args' => sub {
    package WithPlan;
    Test::Most->import( 'no_plan', import => [qw( ok )] );
    main::ok( defined( &WithPlan::ok ),         'ok was imported' );
    main::ok( !defined( &WithPlan::cmp_deeply ), 'cmp_deeply not exported' );
};

subtest 'positional blessed alongside import list is honored' => sub {
    package WithBlessed;
    Test::Most->import( 'blessed', import => [qw( ok )] );
    main::ok( defined( &WithBlessed::blessed ),
        'blessed listed positionally still gets exported' );
    main::ok( defined( &WithBlessed::ok ), 'ok from import list exported' );
};

subtest 'module exclusion still applies' => sub {
    package WithoutDeep;
    Test::Most->import( '-Test::Deep', import => [qw( ok )] );
    main::ok( defined( &WithoutDeep::ok ), 'ok exported' );
    main::ok( !defined( &WithoutDeep::cmp_deeply ),
        'Test::Deep symbols not exported even if Test::Deep stayed loaded' );
};

done_testing;
