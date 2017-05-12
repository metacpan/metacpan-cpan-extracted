use strict;
use warnings;
use Test::More;

use Text::Tweet;

my $cnt = 0;

my $simple_tweeter = Text::Tweet->new({
	hashtags_at_end => 1,
});

for (
	[
		[ "Perl YAPC Linux \t \t    \t London Ice \n Beer Par", \"http://www.perl.org/" ],
		[ "Perl", "Linux", "Beer" ],
		"Perl YAPC Linux London Ice Beer Par http://www.perl.org/ #perl #linux #beer"
	],
	[
		[ "\n\nPerl\n",	\"http://www.perl.org/" ],
		[ "Perl", "Linux", "Beer", "Linux" ],
		"Perl http://www.perl.org/ #perl #linux #beer"
	],
	[
		[ "Perl Very long laber and \n its     really very long so long... yeah! Linux London Ice Beer Par XXXXXXXXXXXX", \"http://www.perl.org/" ],
		[ "Perl", "Linux", "Beer" ],
		"Perl Very long laber and its really very long so long... yeah! Linux London Ice Beer Par XXXXXXXXXXXX http://www.perl.org/ #perl #linux"
	],
	[
		[ "\n\nPerl\n", "http://www.perl.org/" ],
		[ "Perl", "Linux", "Beer", "Linux" ],
		"Perl http://www.perl.org/ #perl #linux #beer"
	],
) {
	my ( $textparts, $keywords, $result ) = @{$_}; $cnt++;
	is($simple_tweeter->make($keywords,@{$textparts}),$result,"Checking result of ".$cnt.". test.");
}

my $standard_tweeter = Text::Tweet->new;

for (
	[
		[ "Perl YAPC Linux \t \t    \t London Ice \n Beer Par", \"http://www.perl.org/" ],
		[ "Perl", "Linux", "beer", "jaddajadda" ],
		"#Perl YAPC #Linux London Ice #Beer Par http://www.perl.org/ #jaddajadda"
	],
	[
		[ "Perl Very long laber and \n its     really very long so long... yeah! Linux London Ice Beer Par XXXXXXXXXXXX", \"http://www.perl.org/" ],
		[ "Perl", "Linux", "Beer", "Krieg", "Frieden" ],
		"#Perl Very long laber and its really very long so long... yeah! #Linux London Ice #Beer Par XXXXXXXXXXXX http://www.perl.org/ #krieg"
	],
	[
		[ "1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36" ],
		["1","2","3","11"],
		"#1 #2 #3 4 5 6 7 8 9 10 #11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36"
	],
	[
		[ "\n\nPerl\n", \"http://www.perl.org/" ],
		["Perl","Linux","Beer","Linux"],
		"#Perl http://www.perl.org/ #linux #beer"
	],
) {
	my ( $textparts, $keywords, $result ) = @{$_}; $cnt++;
	is($standard_tweeter->make($keywords,@{$textparts}),$result,"Checking result of ".$cnt.". test.");
}

done_testing;
