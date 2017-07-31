use Test::More;
use Text::Names::GB;

ok(Text::Names::GB::guessGender('David') eq 'M');
ok(Text::Names::GB::guessGender('lkjasdf') == undef);
ok(Text::Names::GB::guessGender('Mary') eq 'F');
ok(Text::Names::GB::guessGender('Arthur') eq 'M');
ok(Text::Names::GB::guessGender('William') eq 'M');
is(Text::Names::GB::guessGender('Bertie'), 'M');
is(Text::Names::GB::guessGender('Barrie'), 'M');
is(Text::Names::GB::guessGender('Kai'), 'M');
is(Text::Names::guessGender('Bertie'), 'F');
is(Text::Names::guessGender('Barrie'), 'F');
is(Text::Names::guessGender('Kai'), 'F');
is(Text::Names::GB::guessGender('Eleni'), 'F');
is(Text::Names::GB::guessGender('Christian'), 'M');
is(Text::Names::GB::guessGender('Arthur Flintstone'), 'M');
is(Text::Names::GB::guessGender("Christian Loew"),"M");
is(Text::Names::GB::guessGender('Natalia'), 'F');
is(Text::Names::GB::guessGender('Ana'), 'F');
is(Text::Names::GB::guessGender('Eleni'), 'F');

done_testing;
