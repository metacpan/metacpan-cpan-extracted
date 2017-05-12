package XML::Filter::Essex::Foo;

$VERSION = 0.000_1;

require XML::Filter::Essex;

@ISA = qw( XML::Filter::Essex );

use strict;

use XML::Essex;

sub main {
    get while !xeof and print $_ and $_ =~ /foo/ || 1;
}

1;
