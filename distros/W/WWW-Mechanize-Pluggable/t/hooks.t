use Test::More tests=>4;

BEGIN {
  use FindBin;

  use lib "$FindBin::Bin/lib";
  use_ok('WWW::Mechanize::Pluggable');
}

my $mech = new WWW::Mechanize::Pluggable;
my @copy;

# If there are plugins already installed, their hooks'll 
# already be in here.
my @base = defined $mech->{PreHooks}->{'get'}
             ? @{$mech->{PreHooks}->{'get'}}
             : ();
my $base_count  = scalar @base;

my $findable = sub { 'sklunch' };

$mech->pre_hook('get', $copy[0] = sub { 'flabadap' });
$mech->pre_hook('get', $copy[1] = sub { 'freen' });
$mech->pre_hook('get', $copy[2] = $findable);
$mech->pre_hook('get', $copy[3] = sub{ 'fshplap' });

is scalar(@{$mech->{PreHooks}->{'get'}}), 4+$base_count, "right number of hooks";
$mech->_remove_hook('PreHooks','get',$findable);

is scalar(@{$mech->{PreHooks}->{'get'}}), 3+$base_count, "right number of hooks";
is_deeply [@{$mech->{PreHooks}->{'get'}}], [@base,@copy[0,1,3]], 'right contents remain';

