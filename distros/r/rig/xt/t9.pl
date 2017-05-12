package UNIVERSAL::SCALAR;
use overload '.' => sub { warn 'ho' };

package main;
use rig io;

my $x;
$x < io '.perlrig';

$x.say();
