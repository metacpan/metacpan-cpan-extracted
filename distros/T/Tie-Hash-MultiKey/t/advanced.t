
# advanced.t

BEGIN { $| = 1; print "1..35\n"; }
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

# test 4	delete element
$exp = 'stooges';
$got = delete $h{moe};
print "got: $got, exp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 5	check for deletions
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

# test 6	delete multiple elements
$got = delete $h{qw(bar jack x)};
$exp = q|y|;
print "got: $got, exp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 7	check for deletions
$exp = q|22	= bless([{
		'dang'	=> 1,
		'ding'	=> 1,
		'dong'	=> 1,
		'quack'	=> 3,
		'quark'	=> 3,
		'quick'	=> 3,
	},
{
		'1'	=> 'dud',
		'3'	=> 'que',
	},
{
		'1'	=> {
			'dang'	=> 3,
			'ding'	=> 2,
			'dong'	=> 4,
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

# test 8	remove one item
$got = (tied %h)->remove('dang');
$exp = q|dud|;
print "got: $got, exp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 9	check for key only deletion
$exp = q|20	= bless([{
		'ding'	=> 1,
		'dong'	=> 1,
		'quack'	=> 3,
		'quark'	=> 3,
		'quick'	=> 3,
	},
{
		'1'	=> 'dud',
		'3'	=> 'que',
	},
{
		'1'	=> {
			'ding'	=> 2,
			'dong'	=> 4,
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

# test 10	remove multiple keys by array
my @got = (tied %h)->remove(qw{ ding quack });
$exp = q|2	= ['que','dud',];
|;
$got = $dd->DumperA(\@got);
print "got: $got, exp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 11	check for removals
$exp = q|16	= bless([{
		'dong'	=> 1,
		'quark'	=> 3,
		'quick'	=> 3,
	},
{
		'1'	=> 'dud',
		'3'	=> 'que',
	},
{
		'1'	=> {
			'dong'	=> 4,
		},
		'3'	=> {
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

# test 12	remove multiple keys by array ref, including a last key
@got = (tied %h)->remove([qw{ dong quark }]);
$exp = q|2	= ['que','dud',];
|;
$got = $dd->DumperA(\@got);
print "got: $got, exp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 13	check for removals
$exp = q|10	= bless([{
		'quick'	=> 3,
	},
{
		'3'	=> 'que',
	},
{
		'3'	=> {
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

# test 14	repopulate the hash
$h{qw( enee meeny miney mo )} = 'chose';
$h{qw( once upon a time )} = 'story';
$exp = q|30	= bless([{
		'a'	=> 6,
		'enee'	=> 5,
		'meeny'	=> 5,
		'miney'	=> 5,
		'mo'	=> 5,
		'once'	=> 6,
		'quick'	=> 3,
		'time'	=> 6,
		'upon'	=> 6,
	},
{
		'3'	=> 'que',
		'5'	=> 'chose',
		'6'	=> 'story',
	},
{
		'3'	=> {
			'quick'	=> 6,
		},
		'5'	=> {
			'enee'	=> 12,
			'meeny'	=> 13,
			'miney'	=> 14,
			'mo'	=> 15,
		},
		'6'	=> {
			'a'	=> 18,
			'once'	=> 16,
			'time'	=> 19,
			'upon'	=> 17,
		},
	},
7,20,'onceuponatime',], '|. $package .q|');
|;
$exp = normalize($exp);
$got = $dd->DumperA(tied %h);
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 15	replicate to standard hash
my %standard = %h;
$exp = q|9	= {
	'a'	=> 'story',
	'enee'	=> 'chose',
	'meeny'	=> 'chose',
	'miney'	=> 'chose',
	'mo'	=> 'chose',
	'once'	=> 'story',
	'quick'	=> 'que',
	'time'	=> 'story',
	'upon'	=> 'story',
};
|;
$got = $dd->DumperA(\%standard);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 16	overwrite with a store
$h{qw( once there were )} = 'bears';
$exp = q|34	= bless([{
		'a'	=> 6,
		'enee'	=> 5,
		'meeny'	=> 5,
		'miney'	=> 5,
		'mo'	=> 5,
		'once'	=> 6,
		'quick'	=> 3,
		'there'	=> 6,
		'time'	=> 6,
		'upon'	=> 6,
		'were'	=> 6,
	},
{
		'3'	=> 'que',
		'5'	=> 'chose',
		'6'	=> 'bears',
	},
{
		'3'	=> {
			'quick'	=> 6,
		},
		'5'	=> {
			'enee'	=> 12,
			'meeny'	=> 13,
			'miney'	=> 14,
			'mo'	=> 15,
		},
		'6'	=> {
			'a'	=> 18,
			'once'	=> 16,
			'there'	=> 21,
			'time'	=> 19,
			'upon'	=> 17,
			'were'	=> 22,
		},
	},
7,23,'oncetherewere',], '|. $package .q|');
|;
$exp = normalize($exp);
$got = $dd->DumperA(tied %h);
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 17	replicate to hash again
%standard = %h;
$exp = q|11	= {
	'a'	=> 'bears',
	'enee'	=> 'chose',
	'meeny'	=> 'chose',
	'miney'	=> 'chose',
	'mo'	=> 'chose',
	'once'	=> 'bears',
	'quick'	=> 'que',
	'there'	=> 'bears',
	'time'	=> 'bears',
	'upon'	=> 'bears',
	'were'	=> 'bears',
};
|;
$got = $dd->DumperA(\%standard);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 18	check keylist
@got = tied(%h)->keylist('there');
$exp = q|6	= ['once','upon','a','time','there','were',];
|;
$got = $dd->DumperA(\@got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 19	check 'keys'
@got = sort keys %h;
$exp = q|11	= ['a','enee','meeny','miney','mo','once','quick','there','time','upon','were',];
|;
$got = $dd->DumperA(\@got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 20	check 'vals'
@got = sort values %h;
$exp = q|11	= ['bears','bears','bears','bears','bears','bears','chose','chose','chose','chose','que',];
|;
$got = $dd->DumperA(\@got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 21	check 'each'
%standard = ();
while (my($k,$v) = each %h) {
  $standard{$k} = $v;
}
# should be the same as test 17
$exp = q|11	= {
	'a'	=> 'bears',
	'enee'	=> 'chose',
	'meeny'	=> 'chose',
	'miney'	=> 'chose',
	'mo'	=> 'chose',
	'once'	=> 'bears',
	'quick'	=> 'que',
	'there'	=> 'bears',
	'time'	=> 'bears',
	'upon'	=> 'bears',
	'were'	=> 'bears',
};
|;
$got = $dd->DumperA(\%standard);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 22	check slice
%standard = ();
my @keys = qw(quick time mo);
my $ps = \%standard;
@{$ps}{@keys} = @h{@keys};
$exp = q|3	= {
	'mo'	=> 'chose',
	'quick'	=> 'que',
	'time'	=> 'bears',
};
|;
$got = $dd->DumperA(\%standard);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 23	check slice with different syntax
%standard = ();
my $hp = \%h;
@{$ps}{@keys} = @{$hp}{@keys};
$got = $dd->DumperA(\%standard);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 24	clear tied hash
%h = ();
$exp = q|6	= bless([{
	},
{
	},
{
	},
0,0,undef,], '|. $package .q|');
|;
$got = $dd->DumperA(tied %h);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 25	direct assignment
%h = (
	hello		=> 'goodbye',
	hola		=> 'goodbye',
	('x','y','z')	=> 'not sliced', # goes in as (x => y, z => 'not sliced')
	['d','e','f']	=> 'hex',
);
$exp = q|33	= bless([{
		'd'	=> 4,
		'e'	=> 4,
		'f'	=> 4,
		'hello'	=> 0,
		'hola'	=> 1,
		'x'	=> 2,
		'z'	=> 3,
	},
{
		'0'	=> 'goodbye',
		'1'	=> 'goodbye',
		'2'	=> 'y',
		'3'	=> 'not sliced',
		'4'	=> 'hex',
	},
{
		'0'	=> {
			'hello'	=> 0,
		},
		'1'	=> {
			'hola'	=> 1,
		},
		'2'	=> {
			'x'	=> 2,
		},
		'3'	=> {
			'z'	=> 3,
		},
		'4'	=> {
			'd'	=> 4,
			'e'	=> 5,
			'f'	=> 6,
		},
	},
5,7,['d','e','f',],
], '|. $package .q|');
|;
$exp = normalize($exp);
$got = $dd->DumperA(tied %h);
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 26	slice assignment
@{$hp}{[qw(x group)],'new'} = qw( consolidate NEW );
$exp = q|36	= bless([{
		'd'	=> 4,
		'e'	=> 4,
		'f'	=> 4,
		'group'	=> 2,
		'hello'	=> 0,
		'hola'	=> 1,
		'new'	=> 5,
		'x'	=> 2,
		'z'	=> 3,
	},
{
		'0'	=> 'goodbye',
		'1'	=> 'goodbye',
		'2'	=> 'consolidate',
		'3'	=> 'not sliced',
		'4'	=> 'hex',
		'5'	=> 'NEW',
	},
{
		'0'	=> {
			'hello'	=> 0,
		},
		'1'	=> {
			'hola'	=> 1,
		},
		'2'	=> {
			'group'	=> 8,
			'x'	=> 2,
		},
		'3'	=> {
			'z'	=> 3,
		},
		'4'	=> {
			'd'	=> 4,
			'e'	=> 5,
			'f'	=> 6,
		},
		'5'	=> {
			'new'	=> 9,
		},
	},
6,10,'new',], '|. $package .q|');
|;
$got = $dd->DumperA(tied %h);
$exp = normalize($exp);
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 27	setup for consolidation
my %slice = (qw(
	a1	aaaa
	a2	aaaa
	a3	aaaa
	b1	bbbb
	b2	bbbb
	b3	bbbb
	b4	bbbb
	c1	cccc
	c2	cccc
));

@keys = sort keys %slice;
@h{@keys} = @slice{@keys};
$exp = q|72	= bless([{
		'a1'	=> 6,
		'a2'	=> 7,
		'a3'	=> 8,
		'b1'	=> 9,
		'b2'	=> 10,
		'b3'	=> 11,
		'b4'	=> 12,
		'c1'	=> 13,
		'c2'	=> 14,
		'd'	=> 4,
		'e'	=> 4,
		'f'	=> 4,
		'group'	=> 2,
		'hello'	=> 0,
		'hola'	=> 1,
		'new'	=> 5,
		'x'	=> 2,
		'z'	=> 3,
	},
{
		'0'	=> 'goodbye',
		'1'	=> 'goodbye',
		'10'	=> 'bbbb',
		'11'	=> 'bbbb',
		'12'	=> 'bbbb',
		'13'	=> 'cccc',
		'14'	=> 'cccc',
		'2'	=> 'consolidate',
		'3'	=> 'not sliced',
		'4'	=> 'hex',
		'5'	=> 'NEW',
		'6'	=> 'aaaa',
		'7'	=> 'aaaa',
		'8'	=> 'aaaa',
		'9'	=> 'bbbb',
	},
{
		'0'	=> {
			'hello'	=> 0,
		},
		'1'	=> {
			'hola'	=> 1,
		},
		'10'	=> {
			'b2'	=> 14,
		},
		'11'	=> {
			'b3'	=> 15,
		},
		'12'	=> {
			'b4'	=> 16,
		},
		'13'	=> {
			'c1'	=> 17,
		},
		'14'	=> {
			'c2'	=> 18,
		},
		'2'	=> {
			'group'	=> 8,
			'x'	=> 2,
		},
		'3'	=> {
			'z'	=> 3,
		},
		'4'	=> {
			'd'	=> 4,
			'e'	=> 5,
			'f'	=> 6,
		},
		'5'	=> {
			'new'	=> 9,
		},
		'6'	=> {
			'a1'	=> 10,
		},
		'7'	=> {
			'a2'	=> 11,
		},
		'8'	=> {
			'a3'	=> 12,
		},
		'9'	=> {
			'b1'	=> 13,
		},
	},
15,19,'c2',], '|. $package .q|');
|;
$got = $dd->DumperA(tied %h);
$exp = normalize($exp);
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 28	consolidate
$exp = 8;
$got = tied(%h)->consolidate;
print "got: $got, exp: $exp\nnot "
        unless $got == $exp;
&ok;

$debug = 0;	# kill debugging because 'vi' is not preserved and varies by platform

# test 29	check consolidated data
$exp = q|58	= bless([{
		'a1'	=> 6,
		'a2'	=> 6,
		'a3'	=> 6,
		'b1'	=> 0,
		'b2'	=> 0,
		'b3'	=> 0,
		'b4'	=> 0,
		'c1'	=> 1,
		'c2'	=> 1,
		'd'	=> 5,
		'e'	=> 5,
		'f'	=> 5,
		'group'	=> 7,
		'hello'	=> 3,
		'hola'	=> 3,
		'new'	=> 2,
		'x'	=> 7,
		'z'	=> 4,
	},
{
		'0'	=> 'bbbb',
		'1'	=> 'cccc',
		'2'	=> 'NEW',
		'3'	=> 'goodbye',
		'4'	=> 'not sliced',
		'5'	=> 'hex',
		'6'	=> 'aaaa',
		'7'	=> 'consolidate',
	},
{
		'0'	=> {
			'b1'	=> 13,
			'b2'	=> 14,
			'b3'	=> 15,
			'b4'	=> 16,
		},
		'1'	=> {
			'c1'	=> 17,
			'c2'	=> 18,
		},
		'2'	=> {
			'new'	=> 9,
		},
		'3'	=> {
			'hello'	=> 0,
			'hola'	=> 1,
		},
		'4'	=> {
			'z'	=> 3,
		},
		'5'	=> {
			'd'	=> 4,
			'e'	=> 5,
			'f'	=> 6,
		},
		'6'	=> {
			'a1'	=> 10,
			'a2'	=> 11,
			'a3'	=> 12,
		},
		'7'	=> {
			'group'	=> 8,
			'x'	=> 2,
		},
	},
8,19,undef,], '|. $package .q|');
|;
$got = $dd->DumperA(tied %h);
$exp = normalize($exp);
$got = normalize($got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 30	check ordered list for ALL
@got = tied(%h)->keylist();
$exp = q|18	= ['hello','hola','x','z','d','e','f','group','new','a1','a2','a3','b1','b2','b3','b4','c1','c2',];
|;
$got = $dd->DumperA(\@got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 31	get slot '0';
@got = tied(%h)->slotlist(0);
$exp = q|8	= ['hello','z','d','x','new','a1','b1','c1',];
|;
$got = $dd->DumperA(\@got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 32	get slot '1'
@got = tied(%h)->slotlist(1);
$exp = q|8	= ['hola',undef,'e','group',undef,'a2','b2','c2',];
|;
$got = $dd->DumperA(\@got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 33	get slot '2'
@got = tied(%h)->slotlist(2);
$exp = q|8	= [undef,undef,'f',undef,undef,'a3','b3',undef,];
|;
$got = $dd->DumperA(\@got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 34	get slot '3'
@got = tied(%h)->slotlist(3);
$exp = q|8	= [undef,undef,undef,undef,undef,undef,'b4',undef,];
|;
$got = $dd->DumperA(\@got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

# test 35	get slot '4'
@got = tied(%h)->slotlist(4);
$exp = q|8	= [undef,undef,undef,undef,undef,undef,undef,undef,];
|;
$got = $dd->DumperA(\@got);
print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
&ok;

