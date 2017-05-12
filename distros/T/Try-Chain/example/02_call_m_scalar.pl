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
# prints string
{
    my $result = __PACKAGE__->new->$call_m('string');
    () = print ++$counter, $result || 'undef', "\n";
}
# prints string
{
    my $result = __PACKAGE__->new->$call_em('string');
    () = print ++$counter, $result || 'undef', "\n";
}
# prints last elemtent of list
{
    my $result = __PACKAGE__->new->$call_m('list');
    () = print ++$counter, $result || 'undef', "\n";
}
# prints value of index
{
    my $result = __PACKAGE__->new->array_ref->$fetch_i(0);
    () = print ++$counter, $result || 'undef', "\n";
}
# prints value of existing index
{
    my $result = __PACKAGE__->new->array_ref->$fetch_ei(0);
    () = print ++$counter, $result || 'undef', "\n";
}
# prints value of key
{
    my $result = __PACKAGE__->new->hash_ref->$fetch_k('key');
    () = print ++$counter, $result || 'undef', "\n";
}
# prints value of existing key
{
    my $result = __PACKAGE__->new->hash_ref->$fetch_ek('key');
    () = print ++$counter, $result || 'undef', "\n";
}

# prints undef because of nothing
{
    my $result = __PACKAGE__->new->nothing->$call_m('string');
    () = print ++$counter, $result || 'undef', "\n";
}
# prints undef because of nothing
{
    my $result = __PACKAGE__->new->nothing->$call_em('string');
    () = print ++$counter, $result || 'undef', "\n";
}
# prints undef because of not existing method
{
    my $result = __PACKAGE__->new->$call_em('string1');
    () = print ++$counter, $result || 'undef', "\n";
}
{
    my $result = __PACKAGE__->new->nothing->$call_m('list');
    () = print ++$counter, $result || 'undef', "\n";
}
{
    my $result = __PACKAGE__->new->nothing->$fetch_i(0);
    () = print ++$counter, $result || 'undef', "\n";
}
{
    my $result = __PACKAGE__->new->nothing->$fetch_k('key');
    () = print ++$counter, $result || 'undef', "\n";
}
# prints undef because of not existing
{
    my $result = __PACKAGE__->new->array_ref->$fetch_ei(1);
    () = print ++$counter, $result || 'undef', "\n";
}
{
    my $result = __PACKAGE__->new->hash_ref->$fetch_ek('key1');
    () = print ++$counter, $result || 'undef', "\n";
}

# $Id$

__END__

Output:
1foo
2foo
3baz
4item
5item
6value
7value
8undef
9undef
10undef
11undef
12undef
13undef
14undef
15undef
