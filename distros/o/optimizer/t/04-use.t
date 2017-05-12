# -*- perl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl -Mblib t/04-use.t'

#########################

use Test;
BEGIN {
  use Config;
  plan (tests => 8); # todo => $Config{useithreads} ? [7,8] : [])
};
my $X = $^X =~ m/\s/ ? qq{"$^X"} : $^X;

ok(`$X -Mblib -e'use optimizer mine => sub { print \$_[0]->name() }; 1;'`,
   'enter');
ok(`$X -Mblib -e'use optimizer extend => sub { print \$_[0]->name() }; 1;'`,
   'enternextstatenullleave');
ok(`$X -Mblib -e'use optimizer callback => sub { print \$_[0]->name() }; 1;'`,
   'enternextstatenullleave');
ok(`$X -Mblib -e'use optimizer q(sub-detect) => sub { print \$_[0]->name() }; 1;'`,
   'leave');
ok(`$X -Mblib -e'use optimizer q(extend-c) => sub { print \$_[0]->name() }; 1;'`,
   'enternextstateleave');
ok(`$X -Mblib -e'use optimizer 'C'; print 1;'`,
   '1');

# the next two failed with ithreads in relocatetopad
#TODO: {
  #local $TODO = "fails with ithreads in pad_alloc" if $Config{useithreads};

  ok(`$X -Mblib -e'use optimizer 'perl'; print 1;'`,
     '1');
  ok(`$X -Mblib -e'no optimizer; print 1;'`,
     '1');
#}
