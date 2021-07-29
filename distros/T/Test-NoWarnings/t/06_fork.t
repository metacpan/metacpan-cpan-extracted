use strict;
use warnings;
use Test::More;

use Config;
BEGIN {
    my $can_fork = $Config{d_fork} || $Config{d_pseudofork} || (
        ($^O eq 'MSWin32' || $^O eq 'NetWare')
        and $Config{useithreads}
        and $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/
    );
    if (!$can_fork) {
        plan skip_all => 'This system cannot fork';
    }
}

plan tests => 2;

use Test::NoWarnings;

pass("just testing");

# if it's working properly, only the parent will conduct a warnings test
my $pid = fork;
die "Forked failed, $!" unless defined $pid;
