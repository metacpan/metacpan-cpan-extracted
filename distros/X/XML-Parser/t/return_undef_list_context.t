use strict;
use warnings;

use Test::More tests => 6;
use XML::Parser;

# ContentModel::children() should return an empty list when there are
# no children (EMPTY/ANY models), not (undef).  Using "return undef"
# in a list-returning method is a classic Perl footgun: it produces a
# one-element list containing undef instead of an empty list.
#
# This means code like:
#   my @kids = $model->children;
#   if (@kids) { ... }  # incorrectly true for EMPTY models
# would silently process undef as a child element.

my %models;

my $p = XML::Parser->new(
    Handlers => {
        Element => sub { $models{ $_[1] } = $_[2] },
    },
);

$p->parse(<<'XML');
<?xml version="1.0"?>
<!DOCTYPE doc [
  <!ELEMENT empty EMPTY>
  <!ELEMENT any ANY>
  <!ELEMENT seq (a,b)>
]>
<doc/>
XML

# EMPTY model has no children
{
    my $m = $models{empty};
    ok( $m->isempty, 'EMPTY model detected' );

    my @kids = $m->children;
    is( scalar @kids, 0,
        'children() returns empty list for EMPTY model' );
}

# ANY model has no children
{
    my $m = $models{any};
    ok( $m->isany, 'ANY model detected' );

    my @kids = $m->children;
    is( scalar @kids, 0,
        'children() returns empty list for ANY model' );
}

# SEQ model has children — should still work
{
    my $m = $models{seq};
    ok( $m->isseq, 'SEQ model detected' );

    my @kids = $m->children;
    is( scalar @kids, 2,
        'children() returns correct count for SEQ model' );
}
