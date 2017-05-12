use strict;
use warnings;

use Text::Overflow;

use Test::More;
use Test::Base -Base;
use Test::Base::Filter;
use Encode;

filters qw/norm chomp u8/;

plan tests => 1 * blocks;
run_is input => 'expected';

sub u8 {
	decode_utf8 $_;
}

sub ttrim {
	my $str  = $_;
	my $args = filter_arguments || '';
	my ($max, $delim) = split /\s*,\s*/, $args;
	Text::Overflow::trim($str, $max || 5, $delim || "...");
}

sub vttrim {
	my $str  = $_;
	my $args = filter_arguments || '';
	my ($max, $delim) = split /\s*,\s*/, $args;
	Text::Overflow::vtrim($str, $max || 10, $delim || "...");
}


__END__
===
--- input ttrim
あああいいい
--- expected
ああ...

===
--- input ttrim
aaaaaa
--- expected
aa...

===
--- input ttrim
あああいい
--- expected
あああいい

===
--- input ttrim
あああいいい
--- expected
ああ...

===
--- input ttrim
あああfoo
--- expected
ああ...

===
--- input ttrim
あああfoo
--- expected
ああ...

===
--- input ttrim
あああいいい
--- expected
ああ...

===
--- input ttrim
あああいいい
--- expected
ああ...




===
--- input vttrim
あああいいい
--- expected
あああ...

===
--- input vttrim
あああいい
--- expected
あああいい

===
--- input vttrim
a23456789012
--- expected
a234567...

