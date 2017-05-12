use Test::More tests => 8;
BEGIN { use_ok('Text::Affixes') };

my $text = "Hello, world. Hello, big world.";
is_deeply(
  get_prefixes($text),
  {
      3 => {
              'Hel' => 2,
              'wor' => 2,
      }
  }
);

is_deeply(
  get_prefixes({min => 1, max => 2},$text),
  {
      1 => {
              'H' => 2,
              'w' => 2,
              'b' => 1,
      },
      2 => {
              'He' => 2,
              'wo' => 2,
              'bi' => 1,
      }
  }
);

$text = "Hello1, 2world";

is_deeply( get_prefixes({min => 2, max => 2}, $text),
  {
	2 => {
		'He' => 1,
	}
  }
);

is_deeply( get_prefixes({min => 2, max => 2, exclude_numbers => 0}, $text),
  {
	2 => {
		'He' => 1,
		'2w' => 1,
	}
  }
);

is_deeply( get_prefixes({min => 2, max => 2, lowercase => 1}, $text),
  {
	2 => {
		'he' => 1,
	}
  }
);

$text = "Hello, hello";
is_deeply( get_prefixes({min => 2, max => 2, lowercase => 1}, $text),
  {
	2 => {
		'he' => 2,
	}
  }
);

is_deeply( get_prefixes({min => 2, max => 2, lowercase => 0}, $text),
  {
	2 => {
		'He' => 1,
		'he' => 1,
	}
  }
);


