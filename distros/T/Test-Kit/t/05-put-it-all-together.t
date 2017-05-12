use lib 't/lib';

# Put it all together - test that all the features work together

use MyTest::PutItAllTogether;

ok(1, "ok() exists");

eval q{fail()};
like($@, qr/Undefined subroutine/, "fail() doesn't exist");

equal("foo", "foo", 'equal() is a renamed is()');

warning_like(
    sub { warn("foo") },
    qr/foo/,
    "warning_like() exists"
);

throws_ok(
    sub { my $x = 1 / 0; },
    qr/division by zero/,
    'throws_ok() exists'
);

done_testing();
