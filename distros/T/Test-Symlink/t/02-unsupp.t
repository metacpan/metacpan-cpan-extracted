use Test::Tester;
use Test::More qw(no_plan);

BEGIN {
  *CORE::GLOBAL::symlink = sub { die "symlink() not supported" };
}

use_ok('Test::Symlink');

check_test( sub { symlink_ok('src1' => 'dst1') },
  { ok => 1,
    type => 'skip',
    reason => 'symlinks are not supported on this platform', },
    'symlink_ok() works when symlinks are not supported');
