# -*- cperl -*-

use Test::More tests => 3 + 21 * 25 ;
use File::Temp qw/ tempdir /;

BEGIN { use_ok('Tie::Cvs') }

# =

my $dir = tempdir( CLEANUP => 1 );

my %tie;
tie %tie, 'Tie::Cvs', $dir;

for(1..25) {
  $tie{"chave $_"} = "Valor de $_$_$_\n";
  ok(1); 			# para mostrar progresso
}

open(R,">_out");
for(keys %tie) { print R "$_\n $tie{$_}\n"};
close R;

$l = 0;
open R, "_out";
while(<R>) { $l++ }
close R;
is($l,75);

unlink "_out";




tie %tie2, 'Tie::Cvs', $dir;

open(R, ">_out");
for(1..20) {
  for(keys %tie2) { print R "$_\n $tie2{$_}\n"; ok(1)};
}
close R;

$l = 0;
open R, "_out";
while(<R>) { $l++ }
close R;

is($l,1500);

