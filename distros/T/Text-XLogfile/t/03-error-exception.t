use strict;
use warnings;
use Test::More tests => 6;
use Text::XLogfile ':all';

my $xlogline = 'a=b:c:d=e';

my $equals_key    = { 'a=b'  => 1 };
my $colon_key     = { 'a:b'  => 1 };
my $newline_key   = { "a\nb" => 1 };

my $colon_value   = { 1 => 'a:b'  };
my $newline_value = { 1 => "a\nb" };

my $x2h = parse_xlogline($xlogline);
ok(!defined($x2h), "a=b:c:d=e returns undef");

for (
    [$equals_key,    "Key 'a=b' contains invalid character: '='."],
    [$colon_key,     "Key 'a:b' contains invalid character: ':'."],
    [$newline_key,   "Key 'a\\nb' contains invalid character: newline."],
    [$colon_value,   "Value 'a:b' (of key '1') contains invalid character: ':'."],
    [$newline_value, "Value 'a\\nb' (of key '1') contains invalid character: newline."],
)
{
    my ($hash, $expected) = @$_;

    eval { make_xlogline($hash) };
    like($@, qr/^\Q$expected/, "Detecting error: \u$expected");
}

