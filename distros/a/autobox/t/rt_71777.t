#!/usr/bin/env perl

use strict;
use warnings;

# simplified version of the test case provided by Tomas Doran (t0m)
# https://rt.cpan.org/Ticket/Display.html?id=71777

# we need to do this manually.
# schwern++: http://www.nntp.perl.org/group/perl.qa/2013/01/msg13351.html
print '1..1', $/;

{
    package Foo;
    use autobox;
    sub DESTROY {
        # confirm a method compiled under "use autobox" doesn't segfault when
        # called during global destruction. the "Can't call method" error is
        # raised by perl's method call function (pp_method_named), which means
        # our version correctly delegated to it, which means our version didn't
        # segfault by trying to access the pointer table after it's been freed
        eval { undef->bar };

        if ($@ =~ /Can't call method "bar" on an undefined value/) {
            print 'ok 1', $/;
        } else { # if it doesn't work, we won't get here
            print 'not ok 1', $/;
        }
    }
}

{
    package Bar;
    sub unused { }
}

my $foo = bless {}, 'Foo';
my $bar = bless {}, 'Bar';

$foo->{bar} = $bar;
$bar->{foo} = $foo;
