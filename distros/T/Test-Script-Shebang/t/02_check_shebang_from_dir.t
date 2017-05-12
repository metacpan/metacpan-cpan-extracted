use strict;
use warnings;
use File::Spec;
use Test::Builder::Tester;
use Test::More;

use Test::Script::Shebang;

NOT_EXISTS_DIR: {
    my $dir = File::Spec->catfile('t', 'bin');
    test_out "not ok 1 - $dir";
    test_fail +2;
    test_err "# $dir dose not exists";
    check_shebang_from_dir $dir;
    test_test 'dir dose not exists';
}

CHECK_DIR: {
    my $dir = File::Spec->catfile('t', 'scripts');
    
    my ($bar, $baz, $foo) = map { File::Spec->catfile($dir, $_) } qw/bar baz foo/;
    
    test_out "not ok 1 - $bar";
    test_fail +7;
    test_err "# $bar is not perl script";
    test_out "not ok 2 - $baz";
    test_fail +4;
    test_err "# Not a shebang file: $baz";
    test_out "ok 3 - $foo";
    test_out "ok 4 - $dir";
    check_shebang_from_dir $dir;
    test_test 'check dir';
}

done_testing;
