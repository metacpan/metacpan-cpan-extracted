use strict;
use warnings;
use Test::More;
use Test::Requires { 'Test::SharedFork' => 0.16 };
use Test::Flatten;

plan skip_all => 'fork is not supported on Win32' if $^O eq 'MSWin32';

subtest 'foo' => sub {
    pass 'parent one';
    pass 'parent two';
    my $pid = fork;
    unless ($pid) {
        pass 'child one';
        pass 'child two';
        pass 'child three';
        exit;
    }
    wait;
    pass 'parent three';
};

done_testing;
