# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tie-Hash-Cache-MRU.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 15 };
use Tie::Hash::Cache::MRU;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

%data = (0..501);

tie %cache, Tie::Hash::Cache::MRU, SIZE => 5, HASH => \%data;
tie %cache2, Tie::Hash::Cache::MRU, SIZE => 5, LIFE => 3, HASH => \%data;


ok($cache{28} == $data{28}); #2
ok($cache{38} == $data{38}); 
ok($cache{48} == $data{48});
ok($cache{58} == $data{58});
ok($cache{68} == $data{68});
ok($cache{78} == $data{78});
ok($cache{88} == $data{88});
ok($cache{98} == $data{98});
ok($cache{24} == $data{24});
ok($cache{22} == $data{22});
$data{22} = 'football';
ok($cache{22} ne $data{22});



sub CURRENT(){0};
sub OLD(){1};
sub TIME(){2}
sub SIZE(){3};
sub LIFE(){4};
sub HASH(){5};
# FETCH, STORE, EXISTS, DELETE, FIRSTKEY, NEXTKEY, CLEAR. DESTROY
sub S(){6};
sub F(){7};
sub D(){8};
sub E(){9};
sub C(){10};
sub FK(){11};
sub NK(){12};
sub DE(){13};

ok($cache2{28} == $data{28});

print STDERR "cache2 TIME: @{[%{tied(%cache2)->[TIME]}]}\n";
print STDERR "cache2 CURRENT: @{[%{tied(%cache2)->[CURRENT]}]}\n";
print STDERR "cache2 OLD: @{[%{tied(%cache2)->[OLD]}]}\n";

$data{28} = 'hockey';
ok($cache2{28} ne $data{28});  # should have stale
print STDERR "sleeping 5\n";sleep 5;
ok($cache2{28} eq $data{28});  # stale should have expired

print STDERR "cache2 TIME: @{[%{tied(%cache2)->[TIME]}]}\n";
print STDERR "cache2 CURRENT: @{[%{tied(%cache2)->[CURRENT]}]}\n";
print STDERR "cache2 OLD: @{[%{tied(%cache2)->[OLD]}]}\n";

