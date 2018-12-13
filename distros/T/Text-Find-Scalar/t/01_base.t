#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Find::Scalar;

diag $];
ok(1); # If we made it this far, we're ok.

my $finder = Text::Find::Scalar->new();
isa_ok( $finder, 'Text::Find::Scalar' );

local $/;
my $string = <DATA>;
my $test = $finder->find($string);

is $test->[0], '$foo';
is $test->[5], '$foo->[5]';
is $test->[9], '$variable';

my $sum   = 0;
while($finder->hasNext()){
  $finder->nextElement();
  ++$sum;
}

is $sum, 13;

my $found = $finder->find();
is $found, undef;

is $finder->find([]), undef;

my @test = $finder->find( $string );
is $test[0], '$foo';
is $test[5], '$foo->[5]';
is $test[9], '$variable';

done_testing();

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
