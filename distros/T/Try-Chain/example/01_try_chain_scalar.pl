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
# prints string
{
    my $result = try_chain { __PACKAGE__->new->string };
    () = print ++$counter, $result || 'undef', "\n";
}
# prints last elemtent of list
{
    my $result = try_chain { __PACKAGE__->new->list };
    () = print ++$counter, $result || 'undef', "\n";
}
# prints value of index
{
    my $result = try_chain { __PACKAGE__->new->array_ref->[0] };
    () = print ++$counter, $result || 'undef', "\n";
}
# prints value of key
{
    my $result = try_chain { __PACKAGE__->new->hash_ref->{key} };
    () = print ++$counter, $result || 'undef', "\n";
}

# prints undef because of nothing
{
    my $result = try_chain { __PACKAGE__->new->nothing->string };
    () = print ++$counter, $result || 'undef', "\n";
}
# prints undef because of nothing
{
    my $result = try_chain { __PACKAGE__->new->nothing->list };
    () = print ++$counter, $result || 'undef', "\n";
}
# prints undef because of nothing
{
    my $result = try_chain { __PACKAGE__->new->nothing->[0] };
    () = print ++$counter, $result || 'undef', "\n";
}
# prints undef because of nothing
{
    my $result = try_chain { __PACKAGE__->new->nothing->{key} };
    () = print ++$counter, $result || 'undef', "\n";
}

# $foo also undef because of no autovivication in block
{
    my $foo;
    my $result = try_chain { no autovivification; return $foo->{bar}[0] };
    () = print ++$counter, $result || 'undef', $foo || 'undef', "\n";
}

# unexpected error message
() = print
    ++$counter,
    try_chain { die "error of try_chain\n" }
        catch { $_ }
        finally { () = print ++$counter, 'try_chain finally', "\n" };
# normal try also imported
() = print
    ++$counter,
    try { die "error of try\n" }
        catch { $_ }
        finally { () = print ++$counter, 'try finally', "\n" };

# $Id$

__END__

Output:
1foo
2baz
3item
4value
5undef
6undef
7undef
8undef
9undefundef
11try_chain finally
11error of try_chai
13try finally
13error of try
