use Test::More tests => 3;
use perl5;

eval '$x = 1';

like $@, qr!Global symbol "\$x" requires explicit package name!,
    'perl5 is strict';

my $x;

is $x // 42, 42, 'dor operator works';

say 'anything';
pass 'I can say anything';
