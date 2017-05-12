{
package JJ;
use sugar moose;
use namespace::autoclean;
has 'name' => ( is=>'rw', isa=>'Str');
}
package main;
#use pet goo;
#use sugar goo;
my $a = new JJ;
say $a;
#JJ::has('aA');
1;
