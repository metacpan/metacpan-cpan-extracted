#!perl -w
use strict;
use Test; BEGIN { plan tests => 3 }


use Unicode::Map;
{
	local $_='value';
	print new Unicode::Map && $_ eq 'value' ?
		  "The Module 'Unicode::Map' without some bug\n" : <DATA>;
}


use Unicode::Lite; ok(1); #$Unicode::Lite::TEST = 1;

sub testing($$;$$)
{
	printf "\tMUTATE: %s -> %s [%u]\n\tOUTPUT: %s\n", 
		   $_[0], $_[1], $_[3]||0, &convert(@_);
}


{
	$_ = "Hallo, schˆne Welt!";

	testing( 'latin1', 'utf8' );
	testing( 'latin1', 'utf7' );
	testing( 'latin1', 'ucs2' );
	testing( 'latin1', 'ucs4' );

	convert( 'latin1', 'utf8' );

	testing( 'utf8', 'latin1' );
	testing( 'utf8', 'unicode' );
	testing( 'utf8', 'utf7' );

	convert( 'utf8', 'utf16' );

	testing( 'utf16', 'latin1' );
	testing( 'utf16', 'utf7' );

	convert( 'utf16', 'latin1' );
	testing( 'latin1', 'latin1', $_, UL_7BT );

	convert( 'latin1', 'latin1', $_, UL_7BT );
	ok($_ eq "Hallo, schoene Welt!")
}



{
	$_ = "è‡®¢•‚, å®‡!";

	testing( 'ibm866', 'utf8' );
	testing( 'ibm866', 'utf7' );
	testing( 'ibm866', 'ucs2' );
	testing( 'ibm866', 'ucs4' );

	convert( 'ibm866', 'utf8' );

	testing( 'utf8', 'ibm866' );
	testing( 'utf8', 'utf16' );

	convert( 'utf8', 'utf16' );

	testing( 'utf16', 'utf8' );
	testing( 'utf16', 'ibm866' );

	convert( 'utf16', 'windows-1251' );

	testing( 'windows-1251', 'ibm866');
	testing( 'windows-1251', 'latin1', $_, UL_CHR );
	testing( 'windows-1251', 'latin1', $_, UL_7BT );

	convert( 'windows-1251', 'latin1', $_, UL_7BT );
	ok($_ eq 'Privet, Mir!');
}






__DATA__

The module Unicode::Map has bug!
To fix bug it, add BUGFIXER LINE at perl/site/lib/Unicode/Map.pm
                   vvvvvvvvvvvvv

    sub _load_registry
    {
         local $_; # !!! BUGFIXER LINE

