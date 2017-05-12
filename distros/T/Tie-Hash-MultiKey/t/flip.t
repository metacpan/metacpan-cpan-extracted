
# flip.t

BEGIN { $| = 1; print "1..3\n"; }
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

*flip = \&Tie::Hash::MultiKey::_flip;	# local test not inherited

$test = 2;


sub ok {
  print "ok $test\n";
  ++$test;
}

my @in = (qw( a b c d z ));

# test 2	check flip of ordinary array
my @out = flip(@in);

my $exp = q|5	= ['z','a','b','c','d',];
|;
my $got = $dd->DumperA(\@out);
print "got: $got\nexp: ". $exp. "\nnot "
	unless $got eq $exp;
&ok;

# test 3	check flip of ref
pop @in;
@out = flip(\@in,'z');
$got = $dd->DumperA(\@out);
print "got: $got\nexp: ". $exp. "\nnot "
	unless $got eq $exp;
&ok;

