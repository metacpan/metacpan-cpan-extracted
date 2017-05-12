#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

use Try::Chain qw( try_chain try catch finally );

our $VERSION = '0.001';
# create an object
sub new {
    return bless {}, __PACKAGE__;
}
# and some methods
sub nothing {
    return;
}
sub string {
    return 'foo';
}
sub list {
    return qw( bar baz );
}
sub array_ref {
    return [ 'item' ];
}
sub hash_ref {
    return { key => 'value' };
}

my $counter = 0;
# prints one string
() = print ++$counter, try_chain { __PACKAGE__->new->string }, "\n";
# prints all elements in list
() = print ++$counter, try_chain { __PACKAGE__->new->list   }, "\n";
# prints value of index
() = print ++$counter, try_chain { __PACKAGE__->new->array_ref->[0] }, "\n";
# prints value of key
() = print ++$counter, try_chain { __PACKAGE__->new->hash_ref->{key} }, "\n";

# prints empty list because of nothing
() = print ++$counter, try_chain { __PACKAGE__->new->nothing->string }, "\n";
# prints empty list because of nothing
() = print ++$counter, try_chain { __PACKAGE__->new->nothing->list }, "\n";
# prints empty list because of nothing, not undef
() = print ++$counter, try_chain { __PACKAGE__->new->nothing->[0] }, "\n";
# prints empty list because of nothing, not undef
() = print ++$counter, try_chain { __PACKAGE__->new->nothing->{key} }, "\n";

# $Id$

__END__

Output:
1foo
2barbaz
3item
4value
5
6
7
8
