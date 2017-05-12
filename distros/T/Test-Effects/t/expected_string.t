use Test::Effects;

plan tests => 1;

$SIG{__WARN__} = sub { die @_; };

effects_ok {
    return 'a string';
}
{
    return => 'a string',
}
=> 'String checking works silently';
