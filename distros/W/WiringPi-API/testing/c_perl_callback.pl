use warnings;
use strict;

use Inline 'C';

package Interrupt;

my %callbacks;

sub new {
    return bless {}, shift;
};
sub interrupt {
    my ($self, $int_num, $cref) = @_;
    $callbacks{$int_num} = $cref;
}
sub interrupt_one {
    print "in interrupt2\n";
    $callbacks{1}->();
}
sub interrupt_two {
    print "in interrupt2\n";
    $callbacks{2}->();
}

1;

package main;

my $obj = Interrupt->new;

$obj->interrupt(1, sub { print "interrupt1\n"; });
$obj->interrupt(2, sub { print "interrupt2\n"; });

interruptOne();
interruptTwo();

__DATA__
__C__

#include <stdlib.h>
#include <stdio.h>

void interruptOne(){
    dSP;
    PUSHMARK(SP);
    call_pv("Interrupt::interrupt_one", G_DISCARD|G_NOARGS);
}

void interruptTwo(){
    dSP;
    PUSHMARK(SP);
    call_pv("Interrupt::interrupt_two", G_DISCARD|G_NOARGS);
}
