#!/usr/bin/perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tree-AVL.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 21;
BEGIN { use_ok('Tree::AVL') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

# create a tree with default constructor
my $avltree;


ok( $avltree = Tree::AVL->new(), 'tree created');


is( $avltree->get_height(), 0, 'the height is 0' ); 

# can insert objects that evaluate to false
eval{
   $avltree->insert("0");  
};
is( $@, '', '$@ is not set after object insert' );


eval{
   $avltree->remove("0");  
};
is( $@, '', '$@ is not set after object removal' );



# can insert strings by default
eval{
   $avltree->insert("arizona");  
};
is( $@, '', '$@ is not set after object insert' );


eval{
   $avltree->insert("arkansas");
};
is( $@, '', '$@ is not set after object insert' );

eval{
   $avltree->insert("massachusetts");  
};
is( $@, '', '$@ is not set after object insert' );

eval{
   $avltree->insert("maryland");  
};
is( $@, '', '$@ is not set after object insert' );

eval{
   $avltree->insert("montana");  
};
is( $@, '', '$@ is not set after object insert' );

eval{
   $avltree->insert("madagascar");  
};
is( $@, '', '$@ is not set after object insert' );

is( $avltree->get_height(), 2, 'the height is 2' ); 


my $root_obj = $avltree->get_root();
is( $root_obj, 'maryland', 'object at root is maryland\n' );

my $obj = $avltree->remove("maryland");
is( $obj, 'maryland', 'object removed is maryland\n' );

is( $obj = $avltree->remove("maryland"), undef, 'object was not found' );


my $iterator;
eval{
   $iterator = $avltree->iterator();
};
is( $@, '', '$@ is not set after retrieve iterator' );


is( $obj = $iterator->(), 'arizona', 'first iterator object is arizona');

eval{
   $iterator = $avltree->iterator(">");
};
is( $@, '', '$@ is not set after retrieve reverse-iterator' );


is( $obj = $iterator->(), 'montana', 'first iterator object is montana');



is( $obj = $avltree->pop_smallest(), 'arizona', 'smallest object is arizona');


is( $obj = $avltree->pop_largest(), 'montana', 'largest object is montana');
