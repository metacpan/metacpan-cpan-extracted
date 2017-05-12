# vim:ft=perl
use Test::More tests => 19;
BEGIN { use_ok("Text::Ngram"); }

my $text = "abcdefg1235678hijklmnop";
my $hash = Text::Ngram::ngram_counts($text, 3);
is_deeply($hash, {
          'abc' => 1,
          'bcd' => 1,
          'cde' => 1,
          'def' => 1,
          'efg' => 1,
          'fg ' => 1,
          ' hi' => 1,
          'hij' => 1,
          'ijk' => 1,
          'jkl' => 1,
          'klm' => 1,
          'lmn' => 1,
          'mno' => 1,
          'nop' => 1,
         }, "Simple test finds all ngrams");
Text::Ngram::add_to_counts("abc", 3, $hash);
is($hash->{abc}, 2, "Simple incremental adding works");
is($hash->{bcd}, 1, "Without messing everything else up");
Text::Ngram::add_to_counts("abc", undef, $hash);
is($hash->{abc}, 3, "We can guess the window size");

my $text2 = "Hello, world. Hello, big world.";
is_deeply(Text::Ngram::ngram_counts({punctuation => 1}, $text2, 3), {
          'ell' => 2,
          ' he' => 1,
          'orl' => 2,
          'hel' => 2,
          ' bi' => 1,
          'wor' => 2,
          'llo' => 2,
          ' wo' => 2,
          'big' => 1,
          'rld' => 2,
          'g w' => 1,
          'ig ' => 1,
          'lo,' => 2,
          ', b' => 1,
          '. h' => 1,
          'd. ' => 1,
          ', w' => 1,
          'ld.' => 2,
          'o, ' => 2,
	});

is_deeply(Text::Ngram::ngram_counts($text2, 3), {
          'ell' => 2,
          'lo ' => 2,
          'ld ' => 2,
          ' he' => 1,
          'orl' => 2,
          'hel' => 2,
          ' bi' => 1,
          'wor' => 2,
          'llo' => 2,
          ' wo' => 2,
          'big' => 1,
          'rld' => 2,
          'g w' => 1,
          'ig ' => 1
	});

is_deeply(Text::Ngram::ngram_counts({punctuation => 0}, $text2, 3), {
          'ell' => 2,
          'lo ' => 2,
          'ld ' => 2,
          ' he' => 1,
          'orl' => 2,
          'hel' => 2,
          ' bi' => 1,
          'wor' => 2,
          'llo' => 2,
          ' wo' => 2,
          'big' => 1,
          'rld' => 2,
          'g w' => 1,
          'ig ' => 1
	});

is_deeply(Text::Ngram::ngram_counts({punctuation => 0}, $text2, 3), {
          'ell' => 2,
          'lo ' => 2,
          'ld ' => 2,
          ' he' => 1,
          'orl' => 2,
          'hel' => 2,
          ' bi' => 1,
          'wor' => 2,
          'llo' => 2,
          ' wo' => 2,
          'big' => 1,
          'rld' => 2,
          'g w' => 1,
          'ig ' => 1
	});

is_deeply(Text::Ngram::ngram_counts({}, $text2, 3), {
          'ell' => 2,
          'lo ' => 2,
          'ld ' => 2,
          ' he' => 1,
          'orl' => 2,
          'hel' => 2,
          ' bi' => 1,
          'wor' => 2,
          'llo' => 2,
          ' wo' => 2,
          'big' => 1,
          'rld' => 2,
          'g w' => 1,
          'ig ' => 1
	});

is_deeply(Text::Ngram::ngram_counts({spaces => 0}, $text2, 3), {
          'ell' => 2,
          'orl' => 2,
          'hel' => 2,
          'wor' => 2,
          'llo' => 2,
          'big' => 1,
          'rld' => 2,
	});

is_deeply( Text::Ngram::ngram_counts($text2, 4),
	{
          'worl' => 2,
          ' hel' => 1,
          'orld' => 2,
          'llo ' => 2,
          ' wor' => 2,
          'ello' => 2,
          'rld ' => 2,
          ' big' => 1,
          'ig w' => 1,
          'big ' => 1,
          'g wo' => 1,
          'hell' => 2
	}
);

my $text3 = "Simple.";
is_deeply( Text::Ngram::ngram_counts($text3),
	{
	  'simpl' => 1,
	  'imple' => 1,
	  'mple ' => 1,
	}
);

is_deeply( Text::Ngram::ngram_counts( {flankbreaks => 0}, $text3),
	{
	  'simpl' => 1,
	  'imple' => 1,
	}
);

is_deeply( Text::Ngram::ngram_counts( {punctuation => 1, flankbreaks => 0}, $text3),
	{
	  'simpl' => 1,
	  'imple' => 1,
	  'mple.' => 1,
	}
);

is_deeply( Text::Ngram::ngram_counts($text3, 5, punctuation => 1, flankbreaks => 0),
	{
	  'simpl' => 1,
	  'imple' => 1,
	  'mple.' => 1,
	}
);

is_deeply( Text::Ngram::ngram_counts($text3, punctuation => 1, flankbreaks => 0),
	{
	  'simpl' => 1,
	  'imple' => 1,
	  'mple.' => 1,
	}
);

# Off-by-on bug
is_deeply(Text::Ngram::ngram_counts('abc', 1), { a => 1, b => 1, c => 1});
is_deeply(Text::Ngram::ngram_counts('abcde', 4), { abcd => 1, bcde => 1 });
