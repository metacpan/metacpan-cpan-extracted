
# multi_as_aref.t

BEGIN { $| = 1; print "1..5\n"; }
END {print "not ok 1\n" unless $loaded;}

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
# rebuild($var);	# converts all the references
#

my $debug = 1;

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

# test 3	add elements		"STORE"
$h{['foo','bar']} = 'baz';
$exp = q|14	= bless([{
		'bar'	=> 0,
		'foo'	=> 0,
	},
{
		'0'	=> 'baz',
	},
{
		'0'	=> {
			'bar'	=> 1,
			'foo'	=> 0,
		},
	},
1,2,['foo','bar',],
], '|. $package .q|');
|;
$got = $dd->DumperA(tied %h);  
$exp = normalize($exp);
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 4	add more keys to foo	"&addkey"
$exp = 'baz';
$got = tied(%h)->addkey([qw(buz)], 'foo');
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
$got = $dd->DumperA(tied %h);
$exp = normalize($exp);
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

