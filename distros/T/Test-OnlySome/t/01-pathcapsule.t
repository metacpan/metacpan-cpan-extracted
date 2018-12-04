#!perl
use rlib 'lib';
use DTest;
use Cwd qw(cwd);
use File::Spec;

BEGIN {
    # Run tests only on Unix-like platforms, because I haven't written
    # Win32 tests yet, and I don't know enough about VMS to write tests there.
    plan skip_all => 'Tests not supported on this platform'
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
# TODO write tests below
# up {{{1

$dut = Test::OnlySome::PathCapsule->new('/foo/bar');
$dut2 = $dut->up();
cmp_ok($dut, '==', $dut2, 'up() returns the instance');

ok($dut->is_dir, 'After up(), it represents a directory');

# }}}1
# down {{{1

$dut = Test::OnlySome::PathCapsule->new('/foo/bar');
ok(!$dut->is_dir, 'Before down(), it represents a file');
$dut2 = $dut->down('bat');
cmp_ok($dut, '==', $dut2, 'down() returns the instance');

ok($dut->is_dir, 'After down(), it represents a directory');
is($dut->file, '', 'After down(), it has no filename');

# }}}1
# file {{{1

# }}}1
# rel / rel_orig {{{1

# }}}1
done_testing();
# vi: set fdm=marker fo-=ro:
