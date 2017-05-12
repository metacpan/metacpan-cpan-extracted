use strict;
use warnings;
use File::Spec;
use Test::Builder::Tester;
use Test::More;

use Test::Script::Shebang;

my $test_dir = 't/scripts';

GOOD_FILE: {
    my $file = File::Spec->catfile($test_dir, 'foo');
    test_out "ok 1 - $file";
    check_shebang $file;
    test_test 'good works';
}

BAD_FILE: {
    my $file = File::Spec->catfile($test_dir, 'bar');
    test_out "not ok 1 - $file";
    test_fail +2;
    test_err "# $file is not perl script";
    check_shebang $file;
    test_test 'not perl script';
}

NOT_A_SHEBANG_FILE: {
    my $file = File::Spec->catfile($test_dir, 'baz');
    test_out "not ok 1 - $file";
    test_fail +2;
    test_err "# Not a shebang file: $file";
    check_shebang $file;
    test_test 'not a shebang file';
}

NOT_EXISTS_FILE: {
    my $file = File::Spec->catfile($test_dir, 'hoge');
    test_out "not ok 1 - $file";
    test_fail +2;
    test_err "# $file dose not exists";
    check_shebang $file;
    test_test 'file dose not exists';
}

done_testing;
