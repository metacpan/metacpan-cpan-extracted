#! perl -w
use strict;

use Test::More;
use Test::NoWarnings ();

use Config;
use File::Path qw/mkpath rmtree/;
use File::Spec::Functions;

{
    my ($base, @tree, @inc);
    BEGIN {
        @inc = @INC;
        $base = catdir('t', 'fallback');
        @tree = ($base);
        push @tree, catdir($base, $Config{archname}, 'auto');
        push @tree, catdir($base, $Config{archname});
        push @tree, catdir($base, $Config{version});
        push @tree, catdir($base, $Config{version}, $Config{archname});
        mkpath($_) for @tree;
    }
    use fallback catdir('t', 'fallback');

    is_deeply([@INC[-5..-1]], [reverse @tree], "Complete stack added to \@INC")
        or diag(explain({tail => [reverse @tree], INC => \@INC}));

    rmtree($base);
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();
