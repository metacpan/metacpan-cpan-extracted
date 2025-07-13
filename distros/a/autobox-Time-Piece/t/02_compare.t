use Time::Piece;
use File::stat;
use Test::More;
use autobox::Time::Piece;
use strict;

my $localtime = localtime();
my $mtime = stat(__FILE__)->mtime;

my @formats = (
	       "%Y-%m-%d",           # 2025-07-12
	       "%d/%m/%Y",           # 12/07/2025
	       "%B %d, %Y",          # July 12, 2025
	       "%a, %d %b %Y",       # Sat, 12 Jul 2025
	       "%m-%d-%y",           # 07-12-25
	       "%j",                 # 193 (day of the year)
	       "%H:%M:%S",           # 14:09:05
	       "%I:%M %p",           # 02:09 PM
	       "%H:%M",              # 14:09
	       "%r",                 # 02:09:05 PM
	       "%Y%m%d_%H%M%S",          # 20250712_140905
	       "%Y-%m-%d_%H-%M-%S",      # 2025-07-12_14-09-05
	       "Week %U, %Y",            # Week 28, 2025
	       "%A the %dᵗʰ of %B %Y",   # Saturday the 12ᵗʰ of July 2025
	       "%s",                     # Unix timestamp
	      );

for my $format (@formats) {
    is($mtime->strptime->strftime($format), localtime($mtime)->strftime($format), $format);
}

done_testing()
