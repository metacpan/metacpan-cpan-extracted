use Test::More 0.88;
use lib 't/lib';


eval q{ use perl5-tbogus; 1 };
like $@, qr/can't locate/i, "dies on trying to import bogus module";


done_testing;
