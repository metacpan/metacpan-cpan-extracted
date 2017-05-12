#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

use XML::Writer::Simpler;

my $class = 'XML::Writer::Simpler';
my $w = $class->new(OUTPUT => 'self');

# can we do everything our parent can do?
SUPER: {
    isa_ok($w, 'XML::Writer');
    can_ok($class, qw{new startTag endTag emptyTag xmlDecl});
}

# can we do our own stuff
SELF: {
    isa_ok($w, $class);
    can_ok($class, qw{new tag});
}

done_testing();
