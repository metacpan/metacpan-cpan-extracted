#! /usr/bin/perl -w

use Text::Reform;

my @name  = (qw(foo foo2 foo3)) x 20;
my @last  = (qw(bar bar2 bar3)) x 20;
my @count = (qw( 3   4    5  )) x 20;

print form
"--------------------------------------------------",
"NAME        LAST                 COUNT",
"--------------------------------------------------",
"[[[[[[[[[   [[[[[[[[[[[[[[[[[[   |||||",
 \@name,     \@last,              \@count;


print form
{ header =>
	"--------------------------------------------------\n" .
	"NAME        LAST                 COUNT\n" .
	"--------------------------------------------------",
  footer => sub {
	my ($pagenum, $lastpage) = @_;
	return "\n\n\nEND OF REPORT" if $lastpage;
	form "\n\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>",
             ".../".($_[0]+1);
  },
  pagelen=>20,
  pagefeed=>"\n\n".("_"x60)."\n\n",
},
"[[[[[[[[[   [[[[[[[[[[[[[[[[[[   |||||",
\@name,  \@last,    \@count;
