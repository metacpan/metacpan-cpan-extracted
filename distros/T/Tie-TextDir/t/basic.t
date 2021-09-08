use strict;
use Test::More;
use Tie::TextDir;
use File::Spec;
use File::Path;

plan tests => 14;
ok 1;

my $dir = "data";

# Just to be sure the dir is empty
rmtree($dir);

{
  my $val = "one line\ntwo lines\nbad stuff\003\005\n";
  
  # 2: open a database
  my %hash;
  ok tie(%hash, 'Tie::TextDir', $dir, 'rw');
  
  # 3: store a value
  $hash{'key'} = $val;
  ok $hash{'key'}, $val;
  
  untie %hash;
  
  # 4: retie the hash
  ok tie(%hash, 'Tie::TextDir', $dir);
  
  # 5: check the stored value
  ok $hash{'key'}, $val;
  
  local $^W;  # Don't generate superfluous warnings here
  
  # 6: check whether the empty key exists()
  is exists $hash{''}, '';
  
  # 7: check whether the . key exists()
  is exists $hash{'.'}, '';
  
  # 8: check whether the .. key exists()
  is exists $hash{'..'}, '';
  
  untie %hash;
  
  # Clean up
  ok tie(%hash, 'Tie::TextDir', $dir, 'rw');
  delete $hash{$_} foreach keys %hash;
  is keys %hash, 0;
  
  rmdir $dir;
  is -e $dir, undef;
}

{
  # Set up an error condition and make sure it's well-handled
 
  my %hash;
  ok tie(%hash, 'Tie::TextDir', $dir, 'rw');
  $hash{foo} = 'bar';
  is $hash{foo}, 'bar';
  
  chmod 0444, File::Spec->catfile($dir, 'foo');
  eval { $hash{foo} = 'baz' };
  
  is keys %hash, 1
      or diag("Expected only 1 key in hash, but found keys @{[keys %hash]}");
}
