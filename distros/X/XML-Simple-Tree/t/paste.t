
use strict;
use XML::Simple::Tree;
use Test::More tests => 6;

my $t1 = 
    XML::Simple::Tree->new( file => 't/data/t1.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

my $exp1 = 
    XML::Simple::Tree->new( file => 't/data/paste_exp1.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

my $cut1 =
    XML::Simple::Tree->new( file => 't/data/paste_cut1.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

$t1->paste_node('ed_last_day_at_cheetahmail', $cut1->get_cnode()->{dir}[0]);

isa_ok($t1, 'XML::Simple::Tree');
is_deeply($t1->get_rnode(), $exp1->get_rnode(), 'paste1');

my $t2 = 
    XML::Simple::Tree->new( file => 't/data/t1.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

my $exp2 = 
    XML::Simple::Tree->new( file => 't/data/paste_exp2.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);

my $cut2 =
    XML::Simple::Tree->new( file => 't/data/paste_cut1.xml', 
                            node_key => 'dir',
                            target_key => 'name'
);


$t2->paste_node('brooklyn_bridge_at_night', $cut2->get_cnode()->{dir}[0]);

isa_ok($t2, 'XML::Simple::Tree');
is_deeply($t2->get_rnode(), $exp2->get_rnode(), 'paste2');

my $t3 =
    XML::Simple::Tree->new( file => 't/data/base.xml',
                            node_key => 'dir',
                            target_key => 'name'
);

my $exp3 =
    XML::Simple::Tree->new( file => 't/data/paste_cut1.xml',
                            node_key => 'dir',
                            target_key => 'name'
);


my $cut3 =
    XML::Simple::Tree->new( file => 't/data/paste_cut1.xml',
                            node_key => 'dir',
                            target_key => 'name'
);


$t3->paste_node('', $cut1->get_rnode()->{dir}[0]);

isa_ok($t3, 'XML::Simple::Tree');
is_deeply($t3->get_rnode(), $exp3->get_rnode(), 'paste_base');

