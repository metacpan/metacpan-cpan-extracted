#use sugar 'bam';
#croak 'bammm';

{
package MyClass;
use rig 'moose';
has 'name' => is=>'rw', isa=>'Str';
}

package main;
#use sugar 'goo';
my $x = 11;
use rig 'bam';
my $c = MyClass->new;
$c->name('aa');
print "Name=" . $c->name;
cluck 'done';
croak 'done';
