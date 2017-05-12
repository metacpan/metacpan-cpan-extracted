use strict;
use warnings;

use Test::More;
END { done_testing() }

use Tie::Hash::Vivify;

my $defaulter = 0;
my $vivi = Tie::Hash::Vivify->new(
  sub { "default" . $defaulter++ },
);

$vivi->{bar} = {};
is_deeply($vivi->{bar}, {}, 'can put a hashref in');
is($vivi->{bar}->{wibble}, undef, "children aren't infected by default");
is($vivi->{foo}, 'default0', 'normal vivification works');

$vivi = Tie::Hash::Vivify->new(
  sub { "default" . $defaulter++ },
  infect_children => 1
);

is($vivi->{foo}, 'default1', 'normal vivification works with infect_children');
$vivi->{bar} = {};
is_deeply($vivi, { foo => 'default1', bar => {} }, 'can put an empty hashref in');
is($vivi->{bar}->{wibble}, 'default2', "children are now infected");

$vivi->{baz} = { quux => 'hlagh', garbleflux => { abc => [qw(a b c)] }};
is_deeply(
  $vivi,
  {
    foo => 'default1',
    bar => { wibble => 'default2' },
    baz => { quux => 'hlagh', garbleflux => { abc => [qw(a b c)] }}
  },
  'can put a complex hashref in'
);

is($vivi->{baz}->{garbleflux}->{hlagh}, 'default3', 'which auto-vivifies all the way down');
is_deeply(
  $vivi,
  {
    foo => 'default1',
    bar => { wibble => 'default2' },
    baz => {
      quux       => 'hlagh',
      garbleflux => {
        abc   => [qw(a b c)],
        hlagh => 'default3',
      }
    }
  },
  'and stores correctly (paranoia!)'
);

$defaulter = 0;
$vivi = Tie::Hash::Vivify->new(
  sub { "default" . $defaulter++ },
  infect_children => 1
);

my $differentdefaulter = 0;
my $vivi2 = Tie::Hash::Vivify->new(
  sub { "differentdefault" . $differentdefaulter++ },
  infect_children => 1
);

$vivi->{poing} = $vivi2;
is($vivi->{poing}->{foo}, 'differentdefault0', "putting a T::H::V hash created with ->new in a T::H::V hash works");
is($vivi->{foo}, 'default0', "and the parent still auto-vivifies properly");

tie my %vivi2, 'Tie::Hash::Vivify', sub { "differentdefault" . $differentdefaulter++ };
$vivi->{poing2} = \%vivi2;
is($vivi->{poing2}->{foo}, 'differentdefault1', "putting a T::H::V hash created with tie in a T::H::V hash works");
is($vivi->{foo2}, 'default1', "and the parent still auto-vivifies properly");

$vivi->{poing}->{bar} = {};
$vivi->{bar} = {};
is($vivi->{poing}->{bar}->{foo}, 'differentdefault2', "child hash infects its children correctly");
is($vivi->{bar}->{foo}, 'default2', "parent hash infects its children correctly");

$defaulter = 0;
$vivi = Tie::Hash::Vivify->new(
  sub { "default" . $defaulter++ },
  infect_children => 1
);
tie(my %notvivi, 'Tie::Hash::Vivify::Test::Hash');
$notvivi{apple} = 'pear';
is(ref(tied(%notvivi)), 'Tie::Hash::Vivify::Test::Hash', "created some other tied hash");
$vivi->{tiedhash} = \%notvivi;
is(ref(tied(%{$vivi->{tiedhash}})), 'Tie::Hash::Vivify::Test::Hash', "can store some other tied hash");
is($vivi->{tiedhash}->{bat}, undef, "but it doesn't get infected");

package Tie::Hash::Vivify::Test::Hash;
sub TIEHASH  { bless [{}], 'Tie::Hash::Vivify::Test::Hash' }
sub STORE    { $_[0]->[0]->{$_[1]} = $_[2] }
sub FETCH    { $_[0]->[0]->{$_[1]} }
sub FIRSTKEY { goto &Tie::Hash::Vivify::FIRSTKEY }
sub NEXTKEY  { goto &Tie::Hash::Vivify::NEXTKEY }
1;
