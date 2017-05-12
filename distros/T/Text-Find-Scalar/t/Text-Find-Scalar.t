# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Text-Find-Scalar.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;

use Text::Find::Scalar;
diag $];
ok(1); # If we made it this far, we're ok.

my $finder = Text::Find::Scalar->new();
ok(defined ref($finder) && ref($finder) eq 'Text::Find::Scalar');

local $/;
my $string = <DATA>;
my $test = $finder->find($string);
ok($test->[0] eq '$foo');
ok($test->[5] eq '$foo->[5]');
ok($test->[9] eq '$variable');

my $check = 13;
my $sum   = 0;
while($finder->hasNext()){
  $finder->nextElement();
  ++$sum;
}
ok($sum == $check);


__DATA__
$foo
${foo}
$foo[2]
$foo{test}
$foo->{bar}
$foo->[5]
"$foo"
"$foo askjlksdf"
'$foo'
'asdkjlsdf $fool '
q~dies ist $ein test~
Dies ist eine $variable
eine $variable und noch "$eine" und '$keine' 
und ne $referenz->{$key}
my @scalars = $_ =~ /(\$\w+(?:->)?\[\$?\w+\])|(\$\w+(?:->)?{\$?\w+})|(\$\w+)|(\${\w+})/og;
<<'EOB';
  $foo
EOB
