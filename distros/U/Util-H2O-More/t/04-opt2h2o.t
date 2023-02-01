use strict;
use warnings;

use Test::More q//;

use Getopt::Long qw/GetOptionsFromArray/;
use Util::H2O::More qw/h2o opt2h2o Getopt2h2o/;

my @getopts = qw/option1=s option2=i option3 option4=s@/;
my $o       = h2o {}, opt2h2o @getopts;

my @ARGV = qw/--option1 foo --option2 12 --option3 --option4 bar --option4 baz/;
GetOptionsFromArray( \@ARGV, $o, @getopts );

note q{opt2h2o ...};
is $o->option1, q{foo}, q{'--option1 STRING' exists as expected};
is $o->option2, 12,     q{'--option2 NUMBER' exists as expected};
is $o->option3, 1,      q{'--option3' exists as expected};
is_deeply $o->option4, [qw/bar baz/], q{'--option4 bar --option4 baz' exists as expected};

@ARGV = qw/--option1 foo --option2 12 --option3 --option4 bar --option4 baz/;
$o = Getopt2h2o \@ARGV, {}, qw/option1=s option2=i option3 option4=s@/;

is $o->option1, q{foo}, q{Getopt2h2os: '--option1 STRING' exists as expected};
is $o->option2, 12,     q{Getopt2h2os: '--option2 NUMBER' exists as expected};
is $o->option3, 1,      q{Getopt2h2os: '--option3' exists as expected};
is_deeply $o->option4, [qw/bar baz/], q{H2oGetopts: '--option4 bar --option4 baz' exists as expected};

done_testing;
