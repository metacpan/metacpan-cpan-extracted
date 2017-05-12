use strict;
use Test;
use Tie::TextDir;
use File::Spec;

plan tests => 14;
ok 1;

my $dir = "data";


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
  ok exists $hash{''}, '';
  
  # 7: check whether the . key exists()
  ok exists $hash{'.'}, '';
  
  # 8: check whether the .. key exists()
  ok exists $hash{'..'}, '';
  
  untie %hash;
  
  # Clean up
  ok tie(%hash, 'Tie::TextDir', $dir, 'rw');
  delete $hash{$_} foreach keys %hash;
  ok keys %hash, 0;
  
  rmdir $dir;
  ok -e $dir, undef;
}

{
  # Set up an error condition and make sure it's well-handled
 
  my %hash;
  ok tie(%hash, 'Tie::TextDir', $dir, 'rw');
  $hash{foo} = 'bar';
  ok $hash{foo}, 'bar';
  
  chmod 0444, File::Spec->catfile($dir, 'foo');
  eval { $hash{foo} = 'baz' };
  
  ok keys %hash, 1;
}
