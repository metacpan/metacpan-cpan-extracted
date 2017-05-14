use Text::Trie qw(Trie walkTrie);

@test = ('abc', 'ab', 'ad', 'x');

sub test {
  print "(@test) converts to\n\t";
  
  @trie = Trie @test;
  walkTrie sub {print("[",shift,"]")}, sub {print(shift)}, sub {print "->"}, 
  sub {print ","}, sub {print "("}, sub {print ")"}, @trie;
  print "\n";
}

print "Default step:\n";
test;
$Text::Trie::step = 2;
print "step = 2:\n";
test;
$Text::Trie::step = 1;
print "step = 1:\n";
test;
