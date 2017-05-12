
# accessor.t

BEGIN { $| = 1; print "1..3\n"; }
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

my %h;

# test 2	check accessor
my $th = tie %h, $package;

my $exp = q|6	= bless([{
	},
{
	},
{
	},
0,0,undef,], '|. $package .q|');
|;
my $got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

# test 3	recheck accessor
$th = tied %h;
$got = $dd->DumperA($th);
print "got: $got\nexp: $exp\nnot "
	unless $got eq $exp;
&ok;

