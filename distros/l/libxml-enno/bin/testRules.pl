#
# For debugging the conversion of ELEMENT models to perl regular expressions
#

use XML::Checker;

@expr = 
(
 "(a|b)",
 "(a?|b+)",
 "(a|b|c|d|e)",
 "(a|b)+",
 "(a,b)",
 "(a?,b+)",
 "(a,b,c,d,e)",
 "(a,b)+",
 "(head, (p | list | note)*, div*)",
 "(#PCDATA|a)*",
 "(#PCDATA|a|b)*",
);

for my $expr (@expr)
{
    my $v = new XML::Checker;
    $v->Element ("bla", $expr);

    my $rule = $v->{ERule}->{bla};
    print "$expr : " . $rule->debug . "\n";
}
