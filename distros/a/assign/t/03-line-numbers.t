use assign::Test;

my $out = capture sub { system "$^X -Ilib $t/line-numbers.pl" };

like $out, qr/warn line 8 at .* line 8\./;

like $out, qr/die line 18 at .* line 18\./;
