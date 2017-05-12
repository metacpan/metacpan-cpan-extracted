package Regex;

use strict;
use warnings;

sub test {
    my $test = shift;

    return $test =~ /blah/;
}

sub test2 {
    my $foo = shift;
    my $bar = shift;

    $foo ? $bar =~ s{test}{}gr : q{};
}

1;
