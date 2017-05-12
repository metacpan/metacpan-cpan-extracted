use strict;
use warnings;
use Test::More;

use Text::LTSV::Liner;
use Term::ANSIColor;

my @keys   = qw/id name score/;
my @values = qw/1 John 99/;

my $line = join("\t", map { "$keys[$_]:$values[$_]" } 0..2);
diag $line;

{
    my $liner = Text::LTSV::Liner->new('no-color' => 1);
    my $parsed = $liner->parse($line);
    is $line, $parsed, q|same with 'no-color' option|;
}
{
    my $liner = Text::LTSV::Liner->new('no-color' => 1, 'no-key' => 1);
    my $parsed = $liner->parse($line);
    is join("\t", @values), $parsed, q|values with 'no-color' and 'no-key' option|;
}

done_testing;
