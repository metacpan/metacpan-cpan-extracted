# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 40 };
use Text::Contraction;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $tc = Text::Contraction->new(words => [ 'a' ]);
ok(($tc->match('a'))[0], 'a');

$tc = Text::Contraction->new(words => [ 'aa' ]);
ok(($tc->match('a'))[0], 'aa');

$tc = Text::Contraction->new(words => [ 'aaa' ]);
ok(($tc->match('a'))[0], undef);

$tc = Text::Contraction->new(words => [ 'a', 'A' ]);
my @m = sort $tc->match('a');
ok(0+@m, 2);
ok($m[0], 'A');
ok($m[1], 'a');

$tc = Text::Contraction->new(words => [ 'a', 'aa' ]);
@m = sort $tc->match('a');
ok(0+@m, 2);
ok($m[0], 'a');
ok($m[1], 'aa');

$tc = Text::Contraction->new(words => [ 'a', 'aa', 'aaa' ]);
@m = sort $tc->match('a');
ok(0+@m, 2);
ok($m[0], 'a');
ok($m[1], 'aa');

$tc = Text::Contraction->new(words => [ 'a', 'ab', 'ba' ]);
@m = sort $tc->match('a');
ok(0+@m, 2);
ok($m[0], 'a');
ok($m[1], 'ab');

@m = $tc->match('b');
ok(0+@m, 1);
ok($m[0], 'ba');

$tc = Text::Contraction->new(words => [ 'a', 'aa', 'aaa' ], minRatio => 0.3);
@m = sort $tc->match('a');
ok(0+@m, 3);
ok($m[0], 'a');
ok($m[1], 'aa');
ok($m[2], 'aaa');

$tc = Text::Contraction->new(words => [ 'a', 'ab', 'ba' ], prefix => '');
@m = sort $tc->match('a');
ok(0+@m, 3);
ok($m[0], 'a');
ok($m[1], 'ab');
ok($m[2], 'ba');

$tc = Text::Contraction->new(words => [ "shall not", "wouldn't" ]);
@m = $tc->match("shan't");
ok(0+@m, 1);
ok($m[0], 'shall not');

@m = $tc->match("won't");
ok(0+@m, 1);
ok($m[0], "wouldn't");

$tc = Text::Contraction->new(words => [ 'a', 'A' ], caseless => 0);
@m = $tc->match('a');
ok(0+@m, 1);
ok($m[0], 'a');

@m = $tc->match('A');
ok(0+@m, 1);
ok($m[0], 'A');

ok($tc->caseless(1),1);

$tc->words(['a', 'A']);
ok($tc->{_words}, undef);

$tc->study();
ok(ref $tc->{_words}, 'ARRAY');

@m = sort $tc->match('a');
ok(0+@m, 2);
ok($m[0], 'A');
ok($m[1], 'a');
