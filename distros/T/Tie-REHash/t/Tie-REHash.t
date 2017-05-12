
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Tie-REHash.t'

use strict;

use Test::More tests => 134;
BEGIN { $^W = 0; } 

{
package Tie::REHash::StringrefBug;
sub TIEHASH { bless {}, $_[0] }
sub STORE { ref $_[1] }
sub FETCH { ref $_[1] }

package Tie::REHash::sub_SCALAR;
sub TIEHASH { bless {}, $_[0] }
sub SCALAR { 1 }
}
tie my %detector, 'Tie::REHash::StringrefBug';
( $detector{\'foo'} = 1 ) eq 'SCALAR'
and $detector{\'foo'} eq 'SCALAR'
#$] >= 5.012 
or diag('
BUG WARNING! Due to bug (rt.perl.org ticket 79178) in your instance of perl, storing/fetching to/from the RegexpKeys hash should avoid escaped literal keys (as well as stringified scalarref keys), like $hash{\"foo"} (or in one statement: $rehash{$key = \"foo"}), or fatal error will result. The workaround: $key = \"foo"; $hash{$key}.
'); 

tie my %detector2, 'Tie::REHash::sub_SCALAR';
scalar(%detector2) == 1
or my $pre_v5_8_3 = 1 , diag("
BUG WARNING! Due to incomplete implementation of hash tie()ing in perls prior to v5.8.3 (this version is $]), evaluating hash (tie()d to Tie::REHash) in scalar context will not work as expected - use tied(%hash)->scalar instead.
");

BEGIN { use_ok('Tie::REHash') };

tie my %hash, 'Tie::REHash';

is((tied %hash)->autodelete_limit, undef);

tie %hash, (tied %hash); # re-tie()ing test
tie %hash, (tied %hash); # re-tie()ing test

ok(!%hash); # initially hash is empty 
is($hash{hash} = 'associative array','associative array');
is($hash{hash}, 'associative array');
ok(exists $hash{hash}); 
ok($pre_v5_8_3 ? tied(%hash)->scalar : scalar(%hash)); 
is($hash{hash} = 'vocabulary', 'vocabulary'); 
is($hash{hash}, 'vocabulary'); 
my $ref2hash_element = \$hash{hash}; 
$$ref2hash_element = 'map'; 
is($hash{hash}, 'map'); 
like($pre_v5_8_3 ? tied(%hash)->scalar : scalar(%hash), qr{\d+/\d+}, 'Standard hash: buckets allocated in scalar context')
or diag('scalar %hash: ' 
. $pre_v5_8_3 ? tied(%hash)->scalar : scalar(%hash));
is(delete $hash{hash}, 'map'); 
ok(!exists $hash{hash}); 
ok(!%hash);

is($hash{qr{car|automobile}} = 'vehicle on wheels','vehicle on wheels');
ok($pre_v5_8_3 ? tied(%hash)->scalar : scalar(%hash)) 
or diag('scalar %hash:' 
. $pre_v5_8_3 ? tied(%hash)->scalar : scalar(%hash));

is($hash{car}, 'vehicle on wheels');
is($hash{automobile}, 'vehicle on wheels');
is($hash{qr{car|automobile}}, 'vehicle on wheels');
ok(exists $hash{car});
ok(exists $hash{automobile});
ok(exists $hash{qr{car|automobile}});

is( delete $hash{car}, 'vehicle on wheels'); 
ok(!exists $hash{car}); 
ok(!defined $hash{car});
is( $hash{automobile} = 'not a luxury' , 'not a luxury'); 
is( $hash{automobile}, 'not a luxury'); 
ok( exists $hash{automobile}); 

is( $hash{miss}, undef); 
ok(!exists $hash{miss}); 

ok( exists $hash{qr{car|automobile}}); 
is( $hash{qr{car|automobile}}, 'vehicle on wheels'); 

is($hash{qr{car|truck}} = 'automobile on wheels', 'automobile on wheels');
is($hash{qr{car|truck}}, 'automobile on wheels'); 
ok( exists $hash{car}); 
is( $hash{car}, 'automobile on wheels'); 
ok( exists $hash{truck});
is( $hash{truck}, 'automobile on wheels');

ok( exists $hash{qr{car|automobile}}); 
is( $hash{qr{car|automobile}}, 'vehicle on wheels'); 
is( delete $hash{qr{car|automobile}}, 'vehicle on wheels');
ok(!exists $hash{qr{car|automobile}}); 
ok(!defined $hash{qr{car|automobile}}); 

ok(!exists $hash{car}); 
ok(!defined $hash{car}); 
ok(!exists $hash{automobile}); 
ok(!defined $hash{automobile}); 

ok( exists $hash{truck});
is( $hash{truck}, 'automobile on wheels');
ok( exists $hash{qr{car|truck}}); 
is( $hash{qr{car|truck}}, 'automobile on wheels');
is( delete $hash{qr{car|truck}}, 'automobile on wheels');
ok(!exists $hash{qr{car|truck}});
ok(!defined $hash{qr{car|truck}});

ok(!exists $hash{truck}); 
ok(!defined $hash{truck});

ok(!%hash);
ok(!keys %hash) if (tied %hash)->remove_dups;

@hash{'foo', 'bar', 'buz'} = (); 
$hash{qr{foo|some}} = 'something';
$hash{miss}; 
$hash{bar} = 'something else';
$hash{some} = 'something else'; 
$hash{qr{buz|zoo}} = 'something else';
$hash{buz} = 'something else yet'; 
is($hash{foo}, 'something'); 
is($hash{bar}, 'something else'); 
is($hash{some}, 'something else'); 
is($hash{zoo}, 'something else'); 
is($hash{buz}, 'something else yet'); 
delete $hash{qr{.*}}; 
is($hash{foo}, undef); 
is($hash{bar}, undef); 
is($hash{some}, undef); 
is($hash{zoo}, undef); 
is($hash{buz}, undef); 
ok(!exists $hash{foo}); 
ok(!exists $hash{bar}); 
ok(!exists $hash{some}); 
ok(!exists $hash{zoo}); 
ok(!exists $hash{buz}); 
ok( $pre_v5_8_3 ? tied(%hash)->scalar : scalar(%hash)); 
is( delete $hash{qr{foo|some}}, 'something');
is( delete $hash{qr{buz|zoo}}, 'something else');
ok(!%hash);
ok(!keys %hash) if (tied %hash)->remove_dups;

my ($sub, $sub2);

$sub = sub{ "calculated value" };
my $rbar = \'bar'; 
is( $hash{$rbar} = $sub, $sub); 
is( $hash{$rbar}, $sub);
is( $hash{ 'bar'}, "calculated value");
ok( exists $hash{$rbar});
ok( exists $hash{ 'bar'});

ok(!defined($hash{$rbar} = 'ignored value')); 
ok(!exists $hash{ 'bar'}); 
ok(!exists $hash{$rbar}); 
ok(!defined $hash{ 'bar'}); 
ok(!defined $hash{$rbar});

$sub2 = sub{ 'calculated value 2' };
my $rfoo = \'foo'; 
is( $hash{\qr{foo|bar}} = $sub2, $sub2);
is( $hash{\qr{foo|bar}}, $sub2);
is( $hash{ qr{foo|bar}}, 'calculated value 2');
is( $hash{ 'foo'}, 'calculated value 2');
is( $hash{$rfoo}, $sub2);
ok( exists $hash{$rfoo});
ok( exists $hash{ 'foo'});
ok(!defined($hash{$rfoo} = 'ignored value')); # same as delete $hash{'foo'}
ok(!exists $hash{ 'foo'}); 
ok(!exists $hash{$rfoo}); 
ok(!defined $hash{ 'foo'}); 
ok(!defined $hash{$rfoo}); 
is( $hash{\qr{foo|bar}}, $sub2);
is( $hash{ qr{foo|bar}}, 'calculated value 2');
ok(!defined($hash{\qr{foo|bar}} = 'ignored value')); # same as delete $hash{'foo'}
ok(!exists $hash{ qr{foo|bar}}); 
ok(!exists $hash{\qr{foo|bar}}); 
ok(!defined $hash{ qr{foo|bar}}); 
ok(!defined $hash{\qr{foo|bar}});

%hash = ();
ok(!%hash);
ok(!keys %hash) if (tied %hash)->remove_dups;

my $rcar = \'car'; 
$hash{$rcar} = sub{ "$_[1] is not a luxury"};
is( $hash{ 'car'}, "car is not a luxury"); 

$hash{\qr{car|automobile}} = sub { "$_[1] is a vehicle on wheels"}; 
is( $hash{car}, "car is a vehicle on wheels"); 

$hash{\qr{(automobile|car)}} = sub { "$1 is a vehicle on wheels"}; 
is( $hash{automobile}, "automobile is a vehicle on wheels"); 

# Finally, exact test of SYNOPSYS from documentation (UPDATE IT as soon as SYNOPSYS is changed)...

no strict qw(refs);

#use Tie::REHash;
tie my %rehash, 'Tie::REHash';
#... %rehash is now almost standard hash, except for the following...

# Regexp keys:...

# basics that you might expect...
$rehash{qr{car|auto|automobile}} = 'vehicle on wheels'; # note qr{}
is($rehash{qr{car|auto|automobile}}, 'vehicle on wheels'); # true
is($rehash{car} , 'vehicle on wheels'); # true
is($rehash{auto} , 'vehicle on wheels'); # true
is($rehash{automobile} , 'vehicle on wheels'); # true
ok(exists $rehash{car}); # true
ok(exists $rehash{auto}); # true
ok(exists $rehash{automobile}); # true
ok(exists $rehash{qr{car|auto|automobile}}); # true

#... and a bit more advanced manipulations:

# then deleting one of matching keys...
delete $rehash{car}; # results in...
ok(not exists $rehash{car}); # true
ok(exists $rehash{auto}); # true
ok(exists $rehash{automobile}); # true
ok(exists $rehash{qr{car|auto|automobile}}); # true

# then altering value of another matching key...
$rehash{auto} = 'automatic';
is($rehash{auto}, 'automatic'); # true
is($rehash{car}, undef); # true (deleted above)
is($rehash{automobile}, 'vehicle on wheels'); # true
is($rehash{qr{car|auto|automobile}}, 'vehicle on wheels'); # true

# then overriding two matching keys at once...
$rehash{qr{car|automobile}} = 'not a luxury';
is($rehash{qr{car|automobile}}, 'not a luxury'); # true
is($rehash{car}, 'not a luxury'); # true
is($rehash{automobile}, 'not a luxury'); # true
is($rehash{auto}, 'automatic'); # still true
is($rehash{qr{car|auto|automobile}}, 'vehicle on wheels'); # still true

#... and so on. 

# Dynamic (calculated) values:...

$hash{\qr{(car|automobile)}} = sub { "$_[1] is a vehicle on wheels" }; 
is($hash{car}, "car is a vehicle on wheels"); # true

1;
