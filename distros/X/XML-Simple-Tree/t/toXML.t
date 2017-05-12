
use strict;
use XML::Simple::Tree;
use Test::More tests => 3;

my $t1 = 
    XML::Simple::Tree->new( file => 't/data/t4.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

my $xml = $t1->toXML();

my $t2 = XML::Simple::Tree->new( string => $xml,
                            node_key => 'dir',
                            target_key => 'name'
);



isa_ok($t1, 'XML::Simple::Tree');
isa_ok($t2, 'XML::Simple::Tree');
is_deeply($t1->get_rnode(), $t2->get_rnode(), 'in == out');
