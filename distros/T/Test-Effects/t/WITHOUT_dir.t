use Test::Effects;
use lib 't/lib';

plan tests => 2;

effects_ok {
    require Test::Effects::Module1;
    1;
}
{
    VERBOSE => 1,
}
=> 'with dir works';


effects_ok {
    require Test::Effects::Module2;
    1;
}
{
    scalar_return => sub { (shift//0) != 1 },
    die           => qr{\ACan't locate Test/Effects/Module2.pm in \@INC},

    VERBOSE => 1,
    WITHOUT => 't/lib/',
}
=> 'WITHOUT dir works';



