#!/usr/bin/perl
use strict;
use Test::More tests => 15;

use Text::Password::Pronounceable;

{
my $pp = Text::Password::Pronounceable->new(6,10);
isa_ok($pp, 'Text::Password::Pronounceable');

my $str = $pp->generate;
ok(length($str) >= 6 && length($str) <= 10);

my $str2 = $pp->generate(5);
ok(length($str2) == 5);

my $str3 = $pp->generate(3,4);
ok(length($str3) >= 3 && length($str3) <= 4);
}

{
my $pp = Text::Password::Pronounceable->new(6);
isa_ok($pp, 'Text::Password::Pronounceable');

my $str = $pp->generate;
ok(length($str) == 6);

my $str2 = $pp->generate(8);
ok(length($str2) == 8);

my $str3 = $pp->generate(3,4);
ok(length($str3) >= 3 && length($str3) <= 4);

}

{
my $pp = Text::Password::Pronounceable->new;
isa_ok($pp, 'Text::Password::Pronounceable');

my $str = $pp->generate;
is($str, q[], 'no lengths, no password');

my $str2 = $pp->generate(10);
ok(length($str2) == 10);

my $str3 = $pp->generate(4,8);
ok(length($str3) >= 4 && length($str3) <= 8);
}
{
# testing generate as a class method

my $str = Text::Password::Pronounceable->generate(6, 10);
ok(length($str) <= 10 && length($str) >= 6);

my $str2 = Text::Password::Pronounceable->generate(3, 4);
ok(length($str2) <= 4 && length($str2) >= 3);

my $str3 = Text::Password::Pronounceable->generate(5);
ok(length($str3) == 5);
}

