use Test::More tests => 37;
use strict;
use warnings;
use Data::Dumper;
use Tree::RB;

diag( "Testing tied hash interface in Tree::RB $Tree::RB::VERSION" );

my %capital;
my $tied = tie(%capital, 'Tree::RB');

isa_ok($tied, 'Tree::RB');

ok(keys %capital == 0, 'Empty hash - no keys');
ok(! exists $capital{'France'}, 'exists on empty hash');

$capital{'France'} = 'Paris';

ok(exists $capital{'France'}, 'exists after insert');
is($capital{'France'}, 'Paris', 'STORE and FETCH work');

my $deleted = delete $capital{'France'};
ok(keys %capital == 0, 'Size check after deleting sole element');
isa_ok($deleted, 'Tree::RB::Node');
ok($deleted->key eq 'France' && $deleted->val eq 'Paris', 'check deleted node');

setup();
ok(keys   %capital == 6, 'Size check (keys) after inserts');

SKIP: {
    skip "tied hash SCALAR method not available in version $]", 1 if $] < 5.008_003;
    ok(scalar %capital == 6, 'Size check (scalar) after inserts');
}

my @keys = qw/Egypt England France Germany Hungary Ireland/;
is_deeply([keys %capital], \@keys, 'check keys list');

is_deeply([values %capital], [qw/Cairo London Paris Berlin Budapest Dublin/], 'check values list');

my ($key, $val);

($key, $val) = each %capital;
ok($key eq 'Egypt' && $val eq 'Cairo', 'each check');

($key, $val) = each %capital;
ok($key eq 'England' && $val eq 'London', 'each check');

($key, $val) = each %capital;
ok($key eq 'France' && $val eq 'Paris', 'each check');

($key, $val) = each %capital;
ok($key eq 'Germany' && $val eq 'Berlin', 'each check');

($key, $val) = each %capital;
ok($key eq 'Hungary' && $val eq 'Budapest', 'each check');

($key, $val) = each %capital;
ok($key eq 'Ireland' && $val eq 'Dublin', 'each check');

($key, $val) = each %capital;
ok(!defined $key && !defined $val , 'each check - no more keys');

undef %capital; 
ok(keys   %capital == 0, 'no keys after clearing hash');
ok(scalar %capital == 0, 'size zero after clearing hash');

untie %capital;
ok(@$tied == 0, 'underlying array is empty after untie');

# Custom sorting

$tied = tie(%capital, 'Tree::RB', sub { $_[1] cmp $_[0] });

isa_ok($tied, 'Tree::RB');
setup();

is_deeply([keys %capital], [reverse @keys], 'check keys list (reverse sort)');
untie %capital;

# Seeking
$tied = tie(%capital, 'Tree::RB');
setup();
can_ok('Tree::RB', 'hseek');

$tied->hseek('Egypt');
$key = each %capital;
is($key, 'Egypt', 'hseek to min key');

$tied->hseek('Germany');
($key, $val) = each %capital;
is($key, 'Germany', 'hseek check key');
$key = each %capital;
is($key, 'Hungary', 'hseek check sequence');

$tied->hseek('Japan');
($key, $val) = each %capital;
is_deeply([$key, $val], [undef, undef],  'hseek to key gt max key');

$tied->hseek('Iceland');
$key = each %capital;
is($key, 'Ireland', 'hseek to non existent key lt max key');

$tied->hseek({-key=> 'Belgium'});
$key = each %capital;
is($key, 'Egypt', 'hseek to key lt min key');

# Reverse Seeking

$tied->hseek({-reverse=> 1});
$key = each %capital;
is($key, 'Ireland', 'reverse hseek to max key');
$key = each %capital;
is($key, 'Hungary', 'reverse hseek check sequence');

$tied->hseek('Germany', {-reverse=> 1});
$key = each %capital;
is($key, 'Germany', 'reverse hseek to existing key');

$tied->hseek('Iceland', {-reverse=> 1});
$key = each %capital;
is($key, 'Hungary', 'reverse hseek to non existing key gt min');

$tied->hseek('Belgium', {-reverse=> 1});
$key = each %capital;
is_deeply($key, undef,  'reverse hseek to non existing key lt min');

$tied->hseek({-reverse=> 1, -key=> 'Panama'});
$key = each %capital;
is($key, 'Ireland', 'reverse hseek to non existing key gt max');

## Helper Functions 

sub setup {
    %capital = (
        France => 'Paris',
        England => 'London',
        Hungary => 'Budapest',
        Ireland => 'Dublin',
        Egypt => 'Cairo',
        Germany => 'Berlin',
    );
} 
