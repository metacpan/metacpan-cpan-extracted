
# add_store_aref.t

BEGIN { $| = 1; print "1..7\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
use Data::Dumper::Sorted;

if ($0 =~ m|/E|) { # see if I am an extension test     
  $package = 'Tie::Hash::MultiKey::ExtensionPrototype';
} else {
  $package = 'Tie::Hash::MultiKey';
}

eval "require $package";
$loaded = 1;
print "ok 1\n";
######################### End of black magic.

my $dd = new Data::Dumper::Sorted;

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

# add    
#
# $var = text of some reference
# $var = normalize($var);
#
# for pre conversion
#
# $var = some reference
# rebuild($var);        # converts all the references
#
my $debug = 1;		# set to ONE to see raw data for debug

sub live {
  (my $var = shift) =~ s/^\d+\s+=//;
  eval "$var";
}

sub rebuild {
  return if $debug;
  my $self = shift;
  my($kh,$vh,$sh) = @{$self};
  my %seen;
  my $i = 0;
  my $nkh;
  foreach (sort keys %$kh) {
    my $v = $kh->{$_};
    unless (exists $seen{$v}) {
      $seen{$v} = $i++
    }
    $nkh->{$_} = $seen{$v};
  }
  $self->[0] = $nkh;
  my $nvh = {};		# new value hash
  my $nsh = {};		# new shared key hash
  while (my($k,$v) = each %$vh) {
    $nvh->{$seen{$k}} = $v;
  }
  $self->[1] = $nvh;
  while (my($k,$v) = each %$sh) {
    map { $v->{$_} = 1 } keys %$v;
    $nsh->{$seen{$k}} = $v;
  }
  $self->[2] = $nsh;
}

sub normalize {
  return shift if $debug;
  my $self = live(shift);
  rebuild($self);
  scalar $dd->DumperA($self);
}
my %h;
tie %h, $package;

# test 2	check data structure
my $exp = q|6	= bless([{
	},
{
	},
{
	},
0,0,undef,], '|. $package .q|');
|;

my $got = $dd->DumperA(tied %h);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 3	add element as reference		"STORE"
my $hp = \%h;
my $gotadd = $hp->{['foo']} = 'baz';
$exp = q|10	= bless([{
		'foo'	=> 0,
	},
{
		'0'	=> 'baz',
	},
{
		'0'	=> {
			'foo'	=> 0,
		},
	},
1,1,undef,], '|. $package .q|');
|;
$exp = normalize($exp);
$got = $dd->DumperA(tied %h);  
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 4	add more keys to foo as reference	"&addkey"
$exp = 'baz';
$got = tied(%h)->addkey([qw(bar buz)],'foo');
print "got: $got, exp: $exp\nnot "
	unless $got && $got eq $exp;
&ok;

# test 5	check that values are actually their
$exp = q|14	= bless([{
		'bar'	=> 0,
		'buz'	=> 0,
		'foo'	=> 0,
	},
{
		'0'	=> 'baz',
	},
{
		'0'	=> {
			'bar'	=> 1,
			'buz'	=> 2,
			'foo'	=> 0,
		},
	},
1,3,undef,], '|. $package .q|');
|;
$exp = normalize($exp);
$got = $dd->DumperA(tied %h);
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 6	bad addkey
$exp = q|key 'not_there' does not exist
|;
eval {
	tied(%h)->addkey([qw(once upon a time)], 'not_there');
};
($got = $@) =~ s/\s+at.*//;
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# see test 3
# test 7	check store return of item value
print "got: $gotadd, exp: baz\nnot "
	unless $gotadd eq 'baz';
&ok;
