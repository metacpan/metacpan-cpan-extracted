package Monkey::A;

sub new { bless {}, $_[0] }

sub meth_a { 'in Monkey::A meth_a' }

sub heritable { 'in Monkey::A heritable' }

1;
