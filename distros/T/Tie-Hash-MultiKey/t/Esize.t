
# size.t

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
$h{qw(ding dang dong)} = 'dud';
$h{'x'} = 'y';
$h{qw(quick quack quark)} = 'que';
$h{qw(manny moe jack)} = 'stooges';

$exp = q|40	= bless([{
		'bar'	=> 0,
		'dang'	=> 1,
		'ding'	=> 1,
		'dong'	=> 1,
		'foo'	=> 0,
		'jack'	=> 4,
		'manny'	=> 4,
		'moe'	=> 4,
		'quack'	=> 3,
		'quark'	=> 3,
		'quick'	=> 3,
		'x'	=> 2,
	},
{
		'0'	=> 'baz',
		'1'	=> 'dud',
		'2'	=> 'y',
		'3'	=> 'que',
		'4'	=> 'stooges',
	},
{
		'0'	=> {
			'bar'	=> 1,
			'foo'	=> 0,
		},
		'1'	=> {
			'dang'	=> 3,
			'ding'	=> 2,
			'dong'	=> 4,
		},
		'2'	=> {
			'x'	=> 5,
		},
		'3'	=> {
			'quack'	=> 7,
			'quark'	=> 8,
			'quick'	=> 6,
		},
		'4'	=> {
			'jack'	=> 11,
			'manny'	=> 9,
			'moe'	=> 10,
		},
	},
5,12,'mannymoejack',], '|. $package .q|');
|;
$exp = normalize($exp);
$got = $dd->DumperA(tied %h);  
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 4	get size
$exp = 5;
$got = (tied %h)->size;
print "got: $got, exp: $exp\nnot "
	unless $got == $exp;
&ok;

# test 5	delete element
$exp = 'stooges';
$got = delete $h{moe};
print "got: $got, exp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 6	check for deletions
$exp = q|32	= bless([{
		'bar'	=> 0,
		'dang'	=> 1,
		'ding'	=> 1,
		'dong'	=> 1,
		'foo'	=> 0,
		'quack'	=> 3,
		'quark'	=> 3,
		'quick'	=> 3,
		'x'	=> 2,
	},
{
		'0'	=> 'baz',
		'1'	=> 'dud',
		'2'	=> 'y',
		'3'	=> 'que',
	},
{
		'0'	=> {
			'bar'	=> 1,
			'foo'	=> 0,
		},
		'1'	=> {
			'dang'	=> 3,
			'ding'	=> 2,
			'dong'	=> 4,
		},
		'2'	=> {
			'x'	=> 5,
		},
		'3'	=> {
			'quack'	=> 7,
			'quark'	=> 8,
			'quick'	=> 6,
		},
	},
5,12,undef,], '|. $package .q|');
|;
$exp = normalize($exp);
$got = $dd->DumperA(tied %h);
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 7	recheck size
$exp = 4;
$got = (tied %h)->size;
print "got: $got, exp: $exp\nnot "
	unless $got == $exp;
&ok;
