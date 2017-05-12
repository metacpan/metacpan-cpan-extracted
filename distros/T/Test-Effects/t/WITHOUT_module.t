use Test::Effects;

plan tests => 1;

effects_ok {
    require Test::Effects::VERBOSE;
    1;
}
{
    scalar_return => sub { (shift//0) != 1 },
    die           => qr{\ACan't locate Test/Effects/VERBOSE.pm in \@INC},

    VERBOSE => 1,
    WITHOUT => 'Test::Effects::VERBOSE',
}
=> 'WITHOUT module works';


