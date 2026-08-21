use strict;
use warnings;

use Test::More q//;
use Test::Exception q//;

use Getopt::Long qw/GetOptionsFromArray/;
use Util::H2O::More qw/h2o opt2h2o Getopt2h2o/;

my @getopts = qw/option1=s option2=i option3! option4=s@/;
my $o       = h2o {}, opt2h2o @getopts;

my @ARGV = qw/--option1 foo --option2 12 --option3 --option4 bar --option4 baz/;
GetOptionsFromArray( \@ARGV, $o, @getopts );

note q{opt2h2o ...};
is $o->option1, q{foo}, q{'--option1 STRING' exists as expected};
is $o->option2, 12,     q{'--option2 NUMBER' exists as expected};
is $o->option3, 1,      q{'--option3' exists as expected};
is_deeply $o->option4, [qw/bar baz/], q{'--option4 bar --option4 baz' exists as expected};

@ARGV = qw/--option1 foo --option2 12 --option3 --option4 bar --option4 baz/;
$o = Getopt2h2o \@ARGV, {}, qw/option1=s option2=i option3! option4=s@/;

is $o->option1, q{foo}, q{Getopt2h2os: '--option1 STRING' exists as expected};
is $o->option2, 12,     q{Getopt2h2os: '--option2 NUMBER' exists as expected};
is $o->option3, 1,      q{Getopt2h2os: '--option3' exists as expected};
is_deeply $o->option4, [qw/bar baz/], q{H2oGetopt: '--option4 bar --option4 baz' exists as expected};

@ARGV = qw/--option1 foo --option2 12 --no-option3 --option4 bar --option4 baz/;
$o = Getopt2h2o \@ARGV, {}, qw/option1=s option2=i option3! option4=s@/;

is $o->option1, q{foo}, q{Getopt2h2os: '--option1 STRING' exists as expected};
is $o->option2, 12,     q{Getopt2h2os: '--option2 NUMBER' exists as expected};
is $o->option3, 0,      q{Getopt2h2os: '--no-option3' (defined with 'option3!') works as expected};
is_deeply $o->option4, [qw/bar baz/], q{H2oGetopt: '--option4 bar --option4 baz' exists as expected};

# testing "-autoundef" option

@ARGV = qw/--option1 foo --option2 12 --option3 --option4 bar --option4 baz/;
$o = Getopt2h2o -autoundef, \@ARGV, {}, qw/option1=s option2=i option3! option4=s@/;

is $o->option1, q{foo}, q{Getopt2h2os: '--option1 STRING' exists as expected};
is $o->option2, 12,     q{Getopt2h2os: '--option2 NUMBER' exists as expected};
is $o->option3, 1,      q{Getopt2h2os: '--option3' exists as expected};
is_deeply $o->option4, [qw/bar baz/], q{H2oGetopt: '--option4 bar --option4 baz' exists as expected};
is $o->doesntexit, undef, q{undefined options return undef with '-autoundef'};


# "-autoundef" must allow reads of missing options but refuse writes.
dies_ok { $o->doesntexit(q{value}) } q{Getopt2h2o '-autoundef' refuses to set a non-existing option};

# An undefined defaults HASH is equivalent to an empty defaults HASH.
@ARGV = qw/--option1 defaultless/;
$o = Getopt2h2o \@ARGV, undef, qw/option1=s/;
is $o->option1, q{defaultless}, q{Getopt2h2o supplies an empty defaults HASH when defaults is undef};

# Bad first arguments are rejected by Getopt::Long rather than being
# accidentally interpreted as the "-autoundef" control option. These
# exercise the remaining short-circuit paths in the option test.
dies_ok { Getopt2h2o() } q{Getopt2h2o without an ARGV array reference dies};
dies_ok { Getopt2h2o 0, {} } q{Getopt2h2o with a false non-ARRAY first argument dies};
dies_ok { Getopt2h2o q{not-an-argv-ref}, {} } q{Getopt2h2o does not mistake an arbitrary string for '-autoundef'};

done_testing;

