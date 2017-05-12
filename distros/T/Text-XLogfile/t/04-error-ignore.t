use strict;
use warnings;
use Test::More tests => 10;
use Text::XLogfile ':all';

my $equals_key    = { 'a=b'  => 1 };
my $colon_key     = { 'a:b'  => 1 };
my $newline_key   = { "a\nb" => 1 };

my $colon_value   = { 1 => 'a:b'  };
my $newline_value = { 1 => "a\nb" };

for (
    [$equals_key,    "a=b=1"],
    [$colon_key,     "a:b=1"],
    [$newline_key,   "a\nb=1"],
    [$colon_value,   "1=a:b"],
    [$newline_value, "1=a\nb"],
)
{
    my ($hash, $expected) = @$_;

    my $logline = eval { make_xlogline($hash, -1) };
    is($@, '', "no error");

    (my $report = $expected) =~ s/\n/\\n/g;
    is($logline, $expected, "Trying to make logline: '$report'");
}

