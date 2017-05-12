
use strict;
use XML::Simple::Tree;
use Test::More tests => 6;

my $t1 = 
    XML::Simple::Tree->new( file => 't/data/t1.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

my $exp1 = 
    XML::Simple::Tree->new( file => 't/data/cut_exp1.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

$t1->cut_node('chicago_and_indiana');

isa_ok($t1, 'XML::Simple::Tree');
is_deeply($t1->get_rnode(), $exp1->get_rnode(), 'cut1');

my $t2 = 
    XML::Simple::Tree->new( file => 't/data/t1.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

my $exp2 = 
    XML::Simple::Tree->new( file => 't/data/cut_exp2.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

$t2->cut_node('ed_last_day_at_cheetahmail');

isa_ok($t2, 'XML::Simple::Tree');
is_deeply($t2->get_rnode(), $exp2->get_rnode(), 'cut2');

my $t3 =
    XML::Simple::Tree->new( file => 't/data/t1.xml',
                            node_key => 'dir',
                            target_key => 'name'
);

my $exp3 =
    XML::Simple::Tree->new( file => 't/data/cut_exp3.xml',
                            node_key => 'dir',
                            target_key => 'name'
);

$t3->cut_node('sanfrancisco');

isa_ok($t3, 'XML::Simple::Tree');
is_deeply($t3->get_rnode(), $exp3->get_rnode(), 'cut3');
