use Test2::V0;

use Test2::Harness2::ChildSubReaper qw/set_child_subreaper have_subreaper_support/;

ok(defined &set_child_subreaper,              'set_child_subreaper imported');
ok(defined &have_subreaper_support,           'have_subreaper_support imported');
ok($Test2::Harness2::ChildSubReaper::VERSION, 'module has a VERSION');

done_testing;
