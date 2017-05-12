#!/usr/bin/perl

use strict;
use warnings;
use Test::Weaken;

# uncomment this to run the ### lines
use Smart::Comments;

{
  # Array::RefElem stored global detected
  use Array::RefElem;
  my $global = 123;
  my $tw = Test::Weaken::leaks
    ({
      constructor => sub {
        my @array;
        my $aref = \@array;
        &Array::RefElem::av_store (\$aref, 0, $global);
        # Array::RefElem::av_store (@$aref, 0, $global);
        return \@array;

        # Array::RefElem::av_store (\@array, 0, $global);
        # return \@array;
      },
     });
  ### $tw
  exit 0;
}

{
  # Tie::RefHash::Weak key objects are detected
  my $global;
  my $tw = Test::Weaken::leaks
    ({
      constructor => sub {
        require Tie::RefHash::Weak;
        my %hash;
        my $key = [ 123 ];
        # $global = $key;
        my $value = [ 456 ];
        tie %hash, 'Tie::RefHash::Weak', $key => $value;
        print values %hash,"\n";
        ### keyaddr: $key+0
        ### tieobj: tied %hash
        return \%hash;
      },
     });
  ### $tw
  exit 0;
}

{
  # Tie::RefHash key objects are detected
  my $global;
  my $tw = Test::Weaken::leaks
    ({
      constructor => sub {
        require Tie::RefHash;
        my %hash;
        my $key = [ 123 ];
        $global = $key;
        my $value = [ 456 ];
        tie %hash, 'Tie::RefHash', $key => $value;
        print values %hash,"\n";
        ### keyaddr: $key+0
        ### tieobj: tied %hash
        return \%hash;
      },
     });
  ### $tw
  exit 0;
}
