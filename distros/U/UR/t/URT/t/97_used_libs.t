use strict;
use warnings;

use Test::More;
require UR::Util;
require Cwd;
require File::Temp;

{
    local @INC = ('/bar');
    local $ENV{PERL5LIB} = '/bar';
    my @used_libs = UR::Util::used_libs();
    ok(eq_array(\@used_libs, []), 'no used_libs');
}
{
    local @INC = ('/foo');
    local $ENV{PERL5LIB} = '';
    my @used_libs = UR::Util::used_libs();
    ok(eq_array(\@used_libs, ['/foo']), 'empty PERL5LIB');
}
{
    local @INC = ('/foo', '/bar', '/baz');
    local $ENV{PERL5LIB} = '/bar:/baz';
    my @used_libs = UR::Util::used_libs();
    ok(eq_array(\@used_libs, ['/foo']), 'multiple dirs in PERL5LIB');
}
{
    local @INC = ('/foo', '/bar');
    local $ENV{PERL5LIB} = '/bar';
    my @used_libs = UR::Util::used_libs();
    ok(eq_array(\@used_libs, ['/foo']), 'only one item in PERL5LIB (no trailing colon)');
}
{
    local @INC = ('/foo', '/bar', '/baz');
    local $ENV{PERL5LIB} = '/bar/:/baz';
    my @used_libs = UR::Util::used_libs();
    ok(eq_array(\@used_libs, ['/foo']), 'first dir in PERL5LIB ends with slash (@INC may not have slash)');
}
{
    local @INC = ('/foo', '/foo', '/bar');
    local $ENV{PERL5LIB} = '/bar';
    my @used_libs = UR::Util::used_libs();
    ok(eq_array(\@used_libs, ['/foo']), 'remove duplicate elements from used_libs');
}
{
    local @INC = ('/foo');
    local $ENV{PERL5LIB} = '';
    local $ENV{PERL_USED_ABOVE} = '/foo/';
    my @used_libs = UR::Util::used_libs();
    ok(eq_array(\@used_libs, ['/foo']), 'remove trailing slash from used_libs');
}
{
    my $orig_dir = Cwd::cwd();
    my $temp_dir = File::Temp::tempdir(CLEANUP => 1);

    $DB::single = 1;
    my @pre_chdir_used_libs = UR::Util::used_libs();
    chdir($temp_dir);
    $DB::single = 1;
    my @post_chdir_used_libs = UR::Util::used_libs();
    chdir($orig_dir);

    is_deeply(\@pre_chdir_used_libs, \@post_chdir_used_libs, 'used_libs returns same libs after chdir');
}

done_testing();
