use strict;
use warnings;

use Test::More tests => 1;

use Text::Table;

### separators and rules
my $tb = Text::Table->new( \'||', 'aaa', \'|', 'bbb', \'|', 'ccc', \'||');

# TEST
is ($tb->rule(
        sub {
            my ($i, $len) = @_;

            return (($i == 0) ? ("X" x $len) : ($i == 2) ? ("Y" x $len) :
                ("A" x $len))
            ;
        },
        sub {
            my ($i, $len) = @_;
            return (($i == 0) ? "|=" : ($i == 3) ? "=|" : "+");
        },
    ),
    "|=XXX+AAA+YYY=|\n",
    "Create a variable rule based on callbacks.",
);

