#! /usr/bin/perl -ws

use Text::Reform;

my $text = join "", map "line $_\n", (1..20);

@lines = form { 
	pagelen=>9,
	header => sub { "Page $_[0]\n"x10 },
	footer => sub { my ($pagenum, $lastpage) = @_;
			return "" if $lastpage;
			return "-"x50 . "\n" . form ">"x50, "...".($pagenum+1);
		      },
	pagefeed => "\n"x10
	},
"      [[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[\n",
       \$text;

print @lines;

