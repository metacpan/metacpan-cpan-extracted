#!/usr/bin/perl -w
#print sum(@ARGV);


#sub sum {
#while ($num = shift) {$total += $num}
#return $total;
#}



package pack1;

$var = <STDIN>;

chop ($var);

package pack2;

$var = <STDIN>;

chop ($var);

package main;

$total = $pack1'var + $pack2'var;

print ("The total is $total.\n");

