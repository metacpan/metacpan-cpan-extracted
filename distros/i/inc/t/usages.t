use strict; use warnings;
use Test::More;
use Cwd();
use File::Spec();

use inc();

my $abs_lib = Cwd::abs_path('lib');
my $cwd = Cwd::cwd;
my $curdir = File::Spec->curdir;

{ # 3 objects
    my $want = join $/, $curdir, $cwd, $abs_lib;
    my @inc = inc->list('dot', 'cwd', 'lib');
    is scalar(@inc), 3, 'Returns 3 values';
    my $got_inc = join $/, @inc;
    is $got_inc, $want, '3 values are correct';
}

done_testing;
