use Test::More tests => 8;
BEGIN { use_ok('Text::Affixes') };

my $text = "Hello, world. Hello, big world.";
is_deeply(
  get_suffixes($text),
  {
      3 => {
              'llo' => 2,
              'rld' => 2,
      }
  });

is_deeply(
  get_suffixes({min => 1, max => 2},$text),
  {
      1 => {
              'o' => 2,
              'd' => 2,
              'g' => 1,
      },
      2 => {
              'lo' => 2,
              'ld' => 2,
              'ig' => 1,
      }
  });

$text = "Hello1, 2worlD";

is_deeply( get_suffixes({min => 2, max => 2}, $text),
  {
	2 => {
		'lD' => 1,
	}
  }
);

is_deeply( get_suffixes({min => 2, max => 2, exclude_numbers => 0}, $text),
  {
	2 => {
		'lD' => 1,
		'o1' => 1,
	}
  }
);

is_deeply( get_suffixes({min => 2, max => 2, lowercase => 1}, $text),
  {
	2 => {
		'ld' => 1,
	}
  }
);

$text = "Hello, hellO";
is_deeply( get_suffixes({min => 2, max => 2, lowercase => 1}, $text),
  {
	2 => {
		'lo' => 2,
	}
  }
);

is_deeply( get_suffixes({min => 2, max => 2, lowercase => 0}, $text),
  {
	2 => {
		'lo' => 1,
		'lO' => 1,
	}
  }
);
