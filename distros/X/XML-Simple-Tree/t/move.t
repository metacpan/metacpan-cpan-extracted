
use strict;
use XML::Simple::Tree;
use Test::More tests => 4;

my $t1 = 
    XML::Simple::Tree->new( file => 't/data/t1.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

my $exp1 = 
    XML::Simple::Tree->new( file => 't/data/move_exp1.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

$t1->move_node('la', 'up');

isa_ok($t1, 'XML::Simple::Tree');
is_deeply($t1->get_rnode(), $exp1->get_rnode(), 'move1');

my $t2 = 
    XML::Simple::Tree->new( file => 't/data/t1.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

my $exp2 = 
    XML::Simple::Tree->new( file => 't/data/move_exp2.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

$t2->move_node('la', 'down');

isa_ok($t2, 'XML::Simple::Tree');
is_deeply($t2->get_rnode(), $exp2->get_rnode(), 'move2');
