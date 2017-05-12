package Monkey::B;

sub new { bless {}, $_[0] }

sub meth_b { 'in Monkey::B meth_b' }

sub already_exists { 'in Monkey::B already_exists' }

1;
