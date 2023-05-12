#!/usr/bin/perl

# Copyright (c) 2015 Paulo Custodio. All Rights Reserved.
# May be used/distributed under the GPL.

use strict;
use warnings;
use Test::More;

my $ms;
my($out,$err,@res);
my $test1 = "test1~";
use_ok 'Text::MacroScript';
require_ok 't/mytests.pl';

sub void(&) { $_[0]->(); () }

# variable expansion
$ms = new_ok('Text::MacroScript', [-embedded => 1]);
is $ms->expand("abc<:%DEFINE_VARIABLE*HELLO*[1+]:>def"), "abcdef";
is $ms->expand("<:#*HELLO*:>"), "1+";
is $ms->expand("<:#*HELL:><:O*:>"), "#*HELLO*";

# multiple line value and counting of []
$ms = new_ok('Text::MacroScript', [-embedded => 1]);
is $ms->expand("a<:%DEFINE_VARIABLE X [:>b"), "ab";
is $ms->expand("c<:[hello:>d"), "cd";
is $ms->expand("e<:|:>f"), "ef";
is $ms->expand("g<:world]:>h"), "gh";
is $ms->expand("i<:]:>j<:#X:>k"), "ij[hello|world]k";

# test embedded options
for ([ [ -embedded => 1 ], 							"<:", ":>" ],
     [ [ -opendelim => "<<", -closedelim => ">>" ], "<<", ">>" ],
     [ [ -opendelim => "!!" ], 						"!!", "!!" ],
	) {
	my($args, $OPEN, $CLOSE) = @$_;
	my @args = @$args;
	note "@args $OPEN $CLOSE";
	
	$ms = new_ok('Text::MacroScript' => [ @args ]);
	t_spew($test1, norm_nl(<<END));
hello ${OPEN}%DEFINE hello
Hallo
%END_DEFINE${CLOSE}world ${OPEN}%DEFINE world
Welt
%END_DEFINE${CLOSE}${OPEN}hello world${CLOSE}
END
	@res = $ms->expand_file($test1);
	is_deeply \@res, ["hello ", "world ", "Hallo\n Welt\n\n"];
	path($test1)->remove;

	$ms = new_ok('Text::MacroScript' => [ @args ]);
	t_spew($test1, norm_nl(<<END));
hello ${OPEN}%DEFINE hello [Hallo]${CLOSE}world${OPEN}%DEFINE world [Welt]${CLOSE}
${OPEN}hello world${CLOSE}
END
	@res = $ms->expand_file($test1);
	is_deeply \@res, ["hello world\n", "Hallo Welt\n"];
	path($test1)->remove;
}

unlink($test1);
done_testing;
