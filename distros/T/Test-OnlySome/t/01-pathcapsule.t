#!perl
use rlib 'lib';
use DTest;
use Cwd qw(cwd);
use File::Spec;

BEGIN {
    # Run tests only on Unix-like platforms, because I haven't written
    # Win32 tests yet, and I don't know enough about VMS to write tests there.
    diag "Running on $^O";
    plan skip_all => 'Tests not yet supported on this platform'
        unless $^O =~ /^(cygwin|darwin|dragonfly|.*bsd|linux|solaris|sunos|svr4)$/;

    use_ok( 'Test::OnlySome::PathCapsule' ) || print "Bail out!\n";
}

my ($dut, $dut2, $vol, $path, $fn);

# Initialization {{{1
$dut = Test::OnlySome::PathCapsule->new;
is($dut->abs, cwd, 'Initializes to cwd');

$dut = Test::OnlySome::PathCapsule->new(cwd, 1);
is($dut->abs, cwd, 'Manual initialization to cwd works');

$dut = Test::OnlySome::PathCapsule->new('foo');
($vol, $path) = File::Spec->splitpath(cwd, true);   # no fn
is($dut->abs, File::Spec->catpath($vol, $path, 'foo'), "Filename in cwd");

$dut = Test::OnlySome::PathCapsule->new('/foo');
is($dut->abs, '/foo', 'Absolute path in root');

$dut = Test::OnlySome::PathCapsule->new('/foo/bar');
is($dut->abs, '/foo/bar', 'Absolute path in subdir');

# }}}1
# clone {{{1
{
    my $curr = $dut->abs;
    my($clone1, $clone2) = ($dut->clone(), $dut->clone());
    cmp_ok($dut, '!=', $clone1, 'Object and clone 1 differ');
    cmp_ok($dut, '!=', $clone2, 'Object and clone 2 differ');
    cmp_ok($clone1, '!=', $clone2, 'Clones 1 and 2 differ');
    is($clone1->abs, $curr, 'Object and clone 1 have the same path');
    is($clone2->abs, $curr, 'Object and clone 2 have the same path');

    $clone1->up();
    is($dut->abs, $curr, "Modifying clone 1 doesn't touch original");
    is($clone2->abs, $curr, "Modifying clone 1 doesn't touch clone 2");
}
# }}}1
# up {{{1

$dut = Test::OnlySome::PathCapsule->new('/foo/bar');
$dut2 = $dut->up();
cmp_ok($dut, '==', $dut2, 'up() returns the instance');

ok($dut->is_dir, 'After up(), it represents a directory');
is($dut->abs, '/', 'up() correctly drops the path component');

# }}}1
# down {{{1

$dut = Test::OnlySome::PathCapsule->new('/foo/bar');
ok(!$dut->is_dir, 'Before down(), it represents a file');
$dut2 = $dut->down('bat');
cmp_ok($dut, '==', $dut2, 'down() returns the instance');

ok($dut->is_dir, 'After down(), it represents a directory');
is($dut->file, '', 'After down(), it has no filename');
is($dut->abs, '/foo/bat', 'down() correctly adds a path component');

$dut = Test::OnlySome::PathCapsule->new('/foo/bar', 1);
ok($dut->is_dir, 'Before down(), it represents a directory');
$dut2 = $dut->down('bat');
cmp_ok($dut, '==', $dut2, 'down() returns the instance');

ok($dut->is_dir, 'After down(), it represents a directory');
is($dut->file, '', 'After down(), it has no filename');
is($dut->abs, '/foo/bar/bat', 'down() correctly adds a path component');

# }}}1
# file {{{1

$dut = Test::OnlySome::PathCapsule->new('/foo/bar');
is($dut->file, 'bar', 'Parser pulls file component');
$dut->file('quux');
is($dut->file, 'quux', 'Can modify file component');
is($dut->abs, '/foo/quux', 'Absolute path is correct after file modification');

# }}}1
# rel / rel_orig {{{1
# TODO add these tests
# }}}1
done_testing();
# vi: set fdm=marker fo-=ro:
