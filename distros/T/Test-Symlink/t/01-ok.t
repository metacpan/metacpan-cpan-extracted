use Test::Tester 0.102;
use Test::More;

my $Symlinks = eval { symlink("",""); 1 }; # Do we have symlink support?

if($Symlinks) {
  plan tests => 59;
} else {
  plan skip_all => 'symlinks are not supported on this platform';
}

cleanup();

open(F, '>dst1'); close(F);
symlink('dst1' => 'src1');	# Link exists
symlink('dst2' => 'src2');	# src exists, dst doesn't

END {
  cleanup();
}

sub cleanup {
  unlink qw(src1 src2 dst1);
}

use_ok('Test::Symlink');

# Things that should work
check_test(sub { symlink_ok('src1', 'dst1', 'Basic usage') },
  { ok => 1,
    name => 'Basic usage', }, 'symlink_ok(), 3 correct arguments');

check_test(sub { symlink_ok('src1', 'dst1') },
  {
    ok => 1,
    name => 'Symlink: src1 -> dst1', }, 'symlink_ok(), 2 correct arguments');

check_test(sub { symlink_ok('src2' => 'dst2') },
  {
    ok => 1,
    name => 'Symlink: src2 -> dst2', diag => ''}, 'symlink_ok(), non-existant dst');

# Things that should fail
check_test(sub { symlink_ok('src3' => 'dst1') },
  { ok => 0,
    name => 'Symlink: src3 -> dst1',
    diag => '    src3 does not exist' },
    'symlink_ok(), non-existant src');

check_test(sub { symlink_ok() },
  { ok => 0,  
    name => 'symlink_ok()',
    diag => '    You must provide a $src argument to symlink_ok()', }, 
    'symlink_ok(), 0 arguments');

check_test(sub { symlink_ok('') },
  { ok => 0,  
    name => 'symlink_ok()',
    diag => '    You must provide a $src argument to symlink_ok()', }, 
    'symlink_ok(), 0 arguments');

check_test(sub { symlink_ok('src1') },
  { ok => 0,
    name => 'symlink_ok(src1)',
    diag => '    You must provide a $dst argument to symlink_ok()', },
    'symlink_ok(), 1 argument');

check_test(sub { symlink_ok('src1' => '') },
  { ok => 0,
    name => 'symlink_ok(src1)',
    diag => '    You must provide a $dst argument to symlink_ok()', },
    'symlink_ok(), 1 argument');

check_test(sub { symlink_ok('dst1' => 'src1') },
  { ok => 0,
    name => 'Symlink: dst1 -> src1',
    diag => '    dst1 exists, but is not a symlink', },
    'symlink_ok(), $src is not a symlink');

check_test(sub { symlink_ok('src1' => 'dst2') },
  { ok => 0,
    name => 'Symlink: src1 -> dst2',
    diag => "    src1 is not a symlink to dst2\n         got: src1 -> dst1\n    expected: src1 -> dst2", },
    'symlink_ok(), $src does not link to $dst');
