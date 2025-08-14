use strict;
use XS::Base qw(has del def clr);
use JSON;
my $x;
#clr();
has("a->b", { c => 1 });      	# set
#my $h = has("a");       		# get deep-cloned value
$x = has("a->b->c");       	# get deep-cloned value
$x = has("a->b->c"); 
print "x: $x\n";

has("a->b->d",3); 
$x = has("a->b->d"); 
print "x: $x\n";

def("a->b->d",5); 
$x = has("a->b->d"); 
print "x: $x\n";

del("a->b->d"); 
$x = has("a->b->d"); 
print "x: $x\n";

$x = has("a->b->c"); 
print "x: $x\n";

