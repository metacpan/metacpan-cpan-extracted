#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Text::Find::Scalar;

my $finder = Text::Find::Scalar->new();

local $/;
my $string = <DATA>;
my $test = $finder->find($string);

my $unique = $finder->unique;
is_deeply $unique, [qw/$foo ${foo} $foo[2] $foo{test} $foo->{bar} $foo->[5] $variable $eine $referenz->{$key} $_/];

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
