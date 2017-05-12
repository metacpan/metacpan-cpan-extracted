# -*- perl -*-

# Test the tabulate fuction.

use 5;
use warnings;
use strict;

use Test::More tests => 12;

# Tests
BEGIN { use_ok('Text::Tabulate'); }

# Load the data.
$/ = '';	# paragraph mode.
my @data = split(/\n/, <DATA>);
ok($#data, 'data loaded');

# Test the routine.

while ($_ = <DATA>)
{
	# Initialisation.
	my $tab = "\t";
	my $pad = " ";
	my $gutter = ' ';
	my $left = '';
	my $right = '';
	my $adjust = '';
	my $top = '';
	my $bottom = '';

	# Load the test
	my ($test, @test) = split(/\n/, $_);
	eval $test;

	#print "$test\n", join("\n", @test), "\n\n";
	#print "max=$max\n";

	# run the test.
	my @result;
	eval {
		@result = tabulate({
			tab=>$tab,
			pad=>$pad,
			gutter=>$gutter,
			left=>$left,
			right=>$right,
			adjust => $adjust,
			top=>$top,
			bottom=>$bottom,
		}, @data);
	};

	if ($@) { warn $@; }
	ok(@result, 'process table');

	# Check.
	is_deeply(\@result, \@test, $test);

	print join("\n", @result), "\n\n";
}

exit;

__DATA__

XXXX	XXXXX	XXXX	XXXX
XXXXXXXX	XX	XXXXXXXXXXXX	XXXXXXXXXXXXXXXX
XXXXXXXX	XX	XXXXXXXXXXXX	XXXXXXXXXXXXXXXXXXXX
XXXXXXXX	XX	XXXXXXXXXXXX	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXX	XX	XXXXXXXXXXXX	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXX	XX	XXXXXXXXXXXX	XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXX	X	X	X	XXXX	XXXXX	XXXXXXXXX
XXX	X	X	X	XXX	XXXX	XXXXXXXXXXXXX
XXXXXX	X	X	X	XXXXXX	XXXXX	XXXXXXXXXXXXX
XXX	X	X	X	XXX	XXXXXXXX	XXXXXXXXXXXXX
XX	X	X	X	XX	XXXXXXXXXXXXXX	XXXXXXXXXXXXX
XXXX	X	X	X	XXXX	XXXXX	XXXXXXXXX
XXXXXXXX	X	X	X	XXXXXXXX	XXXXX	XXXXXXXXXXXXXX
XXXX	X	X	X	XXXX	XXXXX	XXXXXXXXXX
XXXX	X	X	XX	XXXX	XXXXXXXXXXXXXXX	XXXXXXXXXXXXX
XXXX	X	X	XX	XXXX	XXXXXXXXX	

$tab = "\t";
XXXX     XXXXX XXXX         XXXX
XXXXXXXX XX    XXXXXXXXXXXX XXXXXXXXXXXXXXXX
XXXXXXXX XX    XXXXXXXXXXXX XXXXXXXXXXXXXXXXXXXX
XXXXXXXX XX    XXXXXXXXXXXX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXX XX    XXXXXXXXXXXX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXX XX    XXXXXXXXXXXX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXX     X     X            X                                        XXXX     XXXXX           XXXXXXXXX
XXX      X     X            X                                        XXX      XXXX            XXXXXXXXXXXXX
XXXXXX   X     X            X                                        XXXXXX   XXXXX           XXXXXXXXXXXXX
XXX      X     X            X                                        XXX      XXXXXXXX        XXXXXXXXXXXXX
XX       X     X            X                                        XX       XXXXXXXXXXXXXX  XXXXXXXXXXXXX
XXXX     X     X            X                                        XXXX     XXXXX           XXXXXXXXX
XXXXXXXX X     X            X                                        XXXXXXXX XXXXX           XXXXXXXXXXXXXX
XXXX     X     X            X                                        XXXX     XXXXX           XXXXXXXXXX
XXXX     X     X            XX                                       XXXX     XXXXXXXXXXXXXXX XXXXXXXXXXXXX
XXXX     X     X            XX                                       XXXX     XXXXXXXXX

$tab = "\t"; $adjust = 'rcrcllrc'; $pad = '_ ';
____XXXX XXXXX         XXXX                   XXXX
XXXXXXXX  XX   XXXXXXXXXXXX             XXXXXXXXXXXXXXXX
XXXXXXXX  XX   XXXXXXXXXXXX           XXXXXXXXXXXXXXXXXXXX
XXXXXXXX  XX   XXXXXXXXXXXX  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXX  XX   XXXXXXXXXXXX  XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXX  XX   XXXXXXXXXXXX XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
____XXXX   X              X                    X                     XXXX     XXXXX                XXXXXXXXX
_____XXX   X              X                    X                     XXX      XXXX             XXXXXXXXXXXXX
__XXXXXX   X              X                    X                     XXXXXX   XXXXX            XXXXXXXXXXXXX
_____XXX   X              X                    X                     XXX      XXXXXXXX         XXXXXXXXXXXXX
______XX   X              X                    X                     XX       XXXXXXXXXXXXXX   XXXXXXXXXXXXX
____XXXX   X              X                    X                     XXXX     XXXXX                XXXXXXXXX
XXXXXXXX   X              X                    X                     XXXXXXXX XXXXX           XXXXXXXXXXXXXX
____XXXX   X              X                    X                     XXXX     XXXXX               XXXXXXXXXX
____XXXX   X              X                    XX                    XXXX     XXXXXXXXXXXXXXX  XXXXXXXXXXXXX
____XXXX   X              X                    XX                    XXXX     XXXXXXXXX

$tab = "\t"; $pad = '_ '; $gutter = '|'; $right = '<'; $left = '>';
>XXXX    |XXXXX|XXXX        |XXXX                                    |        |               |              <
>XXXXXXXX|XX   |XXXXXXXXXXXX|XXXXXXXXXXXXXXXX                        |        |               |              <
>XXXXXXXX|XX   |XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXX                    |        |               |              <
>XXXXXXXX|XX   |XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  |        |               |              <
>XXXXXXXX|XX   |XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  |        |               |              <
>XXXXXXXX|XX   |XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX|        |               |              <
>XXXX    |X    |X           |X                                       |XXXX    |XXXXX          |XXXXXXXXX     <
>XXX     |X    |X           |X                                       |XXX     |XXXX           |XXXXXXXXXXXXX <
>XXXXXX  |X    |X           |X                                       |XXXXXX  |XXXXX          |XXXXXXXXXXXXX <
>XXX     |X    |X           |X                                       |XXX     |XXXXXXXX       |XXXXXXXXXXXXX <
>XX      |X    |X           |X                                       |XX      |XXXXXXXXXXXXXX |XXXXXXXXXXXXX <
>XXXX    |X    |X           |X                                       |XXXX    |XXXXX          |XXXXXXXXX     <
>XXXXXXXX|X    |X           |X                                       |XXXXXXXX|XXXXX          |XXXXXXXXXXXXXX<
>XXXX    |X    |X           |X                                       |XXXX    |XXXXX          |XXXXXXXXXX    <
>XXXX    |X    |X           |XX                                      |XXXX    |XXXXXXXXXXXXXXX|XXXXXXXXXXXXX <
>XXXX    |X    |X           |XX                                      |XXXX    |XXXXXXXXX      |              <

$tab = "\t"; $pad = '_'; $gutter = '|'; $right = '<'; $left = '>';
>XXXX____|XXXXX|XXXX________|XXXX____________________________________|________|_______________|______________<
>XXXXXXXX|XX___|XXXXXXXXXXXX|XXXXXXXXXXXXXXXX________________________|________|_______________|______________<
>XXXXXXXX|XX___|XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXX____________________|________|_______________|______________<
>XXXXXXXX|XX___|XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX__|________|_______________|______________<
>XXXXXXXX|XX___|XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX__|________|_______________|______________<
>XXXXXXXX|XX___|XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX|________|_______________|______________<
>XXXX____|X____|X___________|X_______________________________________|XXXX____|XXXXX__________|XXXXXXXXX_____<
>XXX_____|X____|X___________|X_______________________________________|XXX_____|XXXX___________|XXXXXXXXXXXXX_<
>XXXXXX__|X____|X___________|X_______________________________________|XXXXXX__|XXXXX__________|XXXXXXXXXXXXX_<
>XXX_____|X____|X___________|X_______________________________________|XXX_____|XXXXXXXX_______|XXXXXXXXXXXXX_<
>XX______|X____|X___________|X_______________________________________|XX______|XXXXXXXXXXXXXX_|XXXXXXXXXXXXX_<
>XXXX____|X____|X___________|X_______________________________________|XXXX____|XXXXX__________|XXXXXXXXX_____<
>XXXXXXXX|X____|X___________|X_______________________________________|XXXXXXXX|XXXXX__________|XXXXXXXXXXXXXX<
>XXXX____|X____|X___________|X_______________________________________|XXXX____|XXXXX__________|XXXXXXXXXX____<
>XXXX____|X____|X___________|XX______________________________________|XXXX____|XXXXXXXXXXXXXXX|XXXXXXXXXXXXX_<
>XXXX____|X____|X___________|XX______________________________________|XXXX____|XXXXXXXXX______|______________<

$tab = "\t"; $pad = '_'; $gutter = '|'; $right = '<'; $left = '>'; $bottom = '^'; $top = 'V';
>VVVVVVVV|VVVVV|VVVVVVVVVVVV|VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV|VVVVVVVV|VVVVVVVVVVVVVVV|VVVVVVVVVVVVVV<
>XXXX____|XXXXX|XXXX________|XXXX____________________________________|________|_______________|______________<
>XXXXXXXX|XX___|XXXXXXXXXXXX|XXXXXXXXXXXXXXXX________________________|________|_______________|______________<
>XXXXXXXX|XX___|XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXX____________________|________|_______________|______________<
>XXXXXXXX|XX___|XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX__|________|_______________|______________<
>XXXXXXXX|XX___|XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX__|________|_______________|______________<
>XXXXXXXX|XX___|XXXXXXXXXXXX|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX|________|_______________|______________<
>XXXX____|X____|X___________|X_______________________________________|XXXX____|XXXXX__________|XXXXXXXXX_____<
>XXX_____|X____|X___________|X_______________________________________|XXX_____|XXXX___________|XXXXXXXXXXXXX_<
>XXXXXX__|X____|X___________|X_______________________________________|XXXXXX__|XXXXX__________|XXXXXXXXXXXXX_<
>XXX_____|X____|X___________|X_______________________________________|XXX_____|XXXXXXXX_______|XXXXXXXXXXXXX_<
>XX______|X____|X___________|X_______________________________________|XX______|XXXXXXXXXXXXXX_|XXXXXXXXXXXXX_<
>XXXX____|X____|X___________|X_______________________________________|XXXX____|XXXXX__________|XXXXXXXXX_____<
>XXXXXXXX|X____|X___________|X_______________________________________|XXXXXXXX|XXXXX__________|XXXXXXXXXXXXXX<
>XXXX____|X____|X___________|X_______________________________________|XXXX____|XXXXX__________|XXXXXXXXXX____<
>XXXX____|X____|X___________|XX______________________________________|XXXX____|XXXXXXXXXXXXXXX|XXXXXXXXXXXXX_<
>XXXX____|X____|X___________|XX______________________________________|XXXX____|XXXXXXXXX______|______________<
>^^^^^^^^|^^^^^|^^^^^^^^^^^^|^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^|^^^^^^^^|^^^^^^^^^^^^^^^|^^^^^^^^^^^^^^<

