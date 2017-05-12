#!perl -T ## no critic (TidyCode)

use strict;
use warnings;

use Try::Chain qw( $call_m $call_em $fetch_i $fetch_ei $fetch_k $fetch_ek );

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
() = print ++$counter, __PACKAGE__->new->$call_m('string'), "\n";

# prints one string
() = print ++$counter, __PACKAGE__->new->$call_em('string'), "\n";
# prints all elements of
() = print ++$counter, __PACKAGE__->new->$call_m('list'), "\n";
# prints value of index
() = print ++$counter, __PACKAGE__->new->array_ref->$fetch_i(0), "\n";
# prints value of existing index
() = print ++$counter, __PACKAGE__->new->array_ref->$fetch_ei(0), "\n";
# prints value of key
() = print ++$counter, __PACKAGE__->new->hash_ref->$fetch_k('key'), "\n";
# prints value of existing key
() = print ++$counter, __PACKAGE__->new->hash_ref->$fetch_ek('key'), "\n";

# prints empty list because of nothing
() = print ++$counter, __PACKAGE__->new->nothing->$call_m('string'), "\n";
# prints empty list because of nothing
# prints empty list because of nothing
() = print ++$counter, __PACKAGE__->new->nothing->$call_em('string'), "\n";
# prints empty list because of not existing method
() = print ++$counter, __PACKAGE__->new->$call_em('string1'), "\n";
# prints empty list because of nothing
() = print ++$counter, __PACKAGE__->new->nothing->$call_m('list'), "\n";
# prints empty list because of nothing, not undef
() = print
    ++$counter,
    map { defined $_ ? $_ : 'undef' }
    __PACKAGE__->new->nothing->$fetch_i(0), "\n";
# prints empty list because of nothing, not undef
() = print
    ++$counter,
    map { defined $_ ? $_ : 'undef' }
    __PACKAGE__->new->nothing->$fetch_k('key'), "\n";
# prints empty list because of not existing, not undef
() = print
    ++$counter,
    map { defined $_ ? $_ : 'undef' }
    __PACKAGE__->new->array_ref->$fetch_ei(1), "\n";
# prints empty list because of nothing, not undef
() = print
    ++$counter,
    map { defined $_ ? $_ : 'undef' }
    __PACKAGE__->new->hash_ref->$fetch_ek('key1'), "\n";

# $Id$

__END__

Output:
1foo
2foo
3barbaz
4item
5item
6value
7value
8
9
10
11
12undef
13undef
14undef
15undef
