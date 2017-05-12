#! perl -w
use strict;
use Data::Dumper;

# $Id$

use Test::More;
my @tests;
BEGIN {
    @tests = (
        { os => $^O, skip => 1, args => '-Uuseperlio -Dusethreads' },
        { os => $^O, skip => 1, args => '-Uuseperlio -Duseithreads' },
        { os => $^O, skip => $^O eq 'MSWin32',
          args => '-Dusethreads -Dusemymalloc' },
        { os => $^O, skip => $^O eq 'MSWin32',
          args => '-Duseithreads -Dusemymalloc' },
        { os => 'MSWin32', skip => 1,
          args => '-Dusethreads -Dusemymalloc' },
        { os => 'MSWin32', skip => 1,
          args => '-Duseithreads -Dusemymalloc' },
        { os => 'MSWin32', skip => 0,
          args => '-Dusethreads -Dusemymalloc -Uuseimpsys' },
        { os => 'MSWin32', skip => 0,
          args => '-Duseithreads -Dusemymalloc -Uuseimpsys' },
    );
    plan tests => 2 + @tests;

    use_ok 'Test::Smoke::Util', 'skip_config';
    require_ok 'Test::Smoke::BuildCFG';
}

for my $test_set ( @tests ) {
    my $args = $test_set->{args};
    local $^O = $test_set->{os};
    my $cfg = Test::Smoke::BuildCFG::new_configuration( $args );
    if ( $test_set->{skip} ) {
        ok skip_config( $cfg ), "skip '$args' [$^O]";
    } else {
        ok !skip_config( $cfg ), "no skip '$args'[$^O]";
    }
}
