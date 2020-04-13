use Test2::V0 -no_srand => 1;
use Wasm::Wasmtime;
use Path::Tiny qw( path );

pass 'preload does not crash';

foreach my $pm (map { $_->relative('lib') } path('lib/Wasm/Wasmtime')->children)
{
  next unless $pm->basename =~ /\.pm/;
  next if $pm->basename eq 'Wat2Wasm.pm';
  is($INC{"$pm"}, T(), "loaded $pm");
}

done_testing;
