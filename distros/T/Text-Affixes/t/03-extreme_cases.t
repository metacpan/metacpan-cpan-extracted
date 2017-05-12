use Test::More tests => 5;
BEGIN { use_ok('Text::Affixes') };

my $text = "Hello, world. Hello, big world.";
my $prefixes = get_prefixes( {}, $text);

is_deeply( $prefixes ,
  # $prefixes now holds
  {
      3 => {
              'Hel' => 2,
              'wor' => 2,
      }
  });

$prefixes = get_prefixes({min => 0, max => 0},$text);

is_deeply( $prefixes ,
  # $prefixes now holds
  { });

$prefixes = get_prefixes({min => 4, max => 3},$text);

is_deeply( $prefixes ,
  # $prefixes now holds
  { });

is_deeply( get_prefixes(), undef );
