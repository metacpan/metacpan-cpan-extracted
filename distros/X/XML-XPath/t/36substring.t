use strict;
use warnings;
use Test::More tests => 12;
use XML::XPath;

my $xp = XML::XPath->new(ioref => *DATA);
ok($xp);

my $cases = <<'...';
substring("12345", 2, 3)              returns "234"
substring("12345", 2)                 returns "2345"
substring("12345", -2)                returns "12345"
substring("12345", 1.5, 2.6)          returns "234"
substring("12345", 0 div 0, 3)        returns ""
substring("12345", 1, 0 div 0)        returns ""
substring("12345", -1 div 0, 1 div 0) returns ""
substring("12345", -42, 1 div 0)      returns "12345"
substring("12345", 0, 1 div 0)        returns "12345"
substring("12345", 0, 3)              returns "12"
substring("12345", -1, 4)             returns "12"
...

for my $case (split /\n/, $cases) {
    next unless $case;

    my ($xpath, $expected) = split / returns /, $case;
    $expected =~ s/"//g;
    is $xp->findvalue($xpath), $expected, $case;
}

# see http://www.w3.org/TR/1999/REC-xpath-19991116#function-substring

__DATA__
<foo/>