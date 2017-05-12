package OtherTypes;

our $foo = 23;
our @foo = "bar";
our %foo = (mouse => "trap");
{
    no warnings;
    # perl warns about the bareword foo. If we use *foo instead the
    # warning goes away, but the *foo{IO} slot doesn't get autoviv'd at
    # compile time.
    open foo, "<", $0;
}

BEGIN { $main::pvio = *foo{IO} }

sub foo { 1 }

use namespace::clean;

1;
