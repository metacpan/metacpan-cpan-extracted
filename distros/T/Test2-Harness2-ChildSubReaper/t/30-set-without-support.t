use Test2::V0;
use POSIX qw/ENOSYS/;

use Test2::Harness2::ChildSubReaper qw/set_child_subreaper have_subreaper_support/;

skip_all "support is present; this test covers the no-support path"
    if have_subreaper_support();

$! = 0;
my $ret = set_child_subreaper(1);
ok(!$ret, 'returns falsy without support');
is(0 + $!, ENOSYS, 'errno set to ENOSYS without support');

done_testing;
