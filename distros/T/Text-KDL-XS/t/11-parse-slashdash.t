use strict;
use warnings;
use Test::More;
use Text::KDL::XS qw(parse_kdl);

# With emit_comments the parser reports slashdashed elements as events
# flagged commented; the tree builder must leave them out all the same.
my %documents = (
    'node'           => "/-a 1\nb 2\n",
    'argument'       => "n 1 /-2 3\n",
    'property'       => "n a=1 /-b=2\n",
    'children block' => "n 1 /-{\n    c\n}\n",
    'nested'         => "/-a {\n    b 1 /* c */ {\n        c k=2\n    }\n}\nz\n",
    'version marker' => "/- kdl-version 2\nnode 1\n",
);

for my $what (sort keys %documents) {
    my $kdl = $documents{$what};
    is_deeply parse_kdl($kdl, emit_comments => 1)->as_data, parse_kdl($kdl)->as_data,
        "slashdashed $what stays out of the tree with emit_comments";
}

my $node = parse_kdl("n 1 /-2 3 a=1 /-b=2 /-{ c }\n", emit_comments => 1)->nodes->[0];
is_deeply [ map { $_->as_perl } @{ $node->args } ], [ 1, 3 ], 'only the live arguments remain';
is_deeply [ map { $_->[0] } @{ $node->props } ], ['a'], 'only the live property remains';
is scalar @{ $node->children }, 0, 'the slashdashed children block is gone';

done_testing;
