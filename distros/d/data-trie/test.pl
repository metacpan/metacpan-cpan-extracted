use strict;
use Test;

BEGIN { plan tests => 7 }

#find the module
use Data::Trie;

#Step 1: creating a letter trie
ok(my $t = Data::Trie->new());

#Steps 2-5: adding some nodes: apples, lemons, oranges, and lemonade
ok($t->add('apples'));
ok($t->add('lemons'));
ok($t->add('oranges'));
ok($t->add('lemonade'));

#print "Step 6: attempting to retrieve the lemons...\n";
my ($result, $data) = $t->lookup('lemons');
ok($result);

#print "Step 7: deleting the lemonade\n";
ok($t->remove('lemonade'));

