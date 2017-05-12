#! /usr/bin/perl -w

use Text::Reform;

sub igpay_atinlay {
	return $2.$1.'way' if $_[0] =~ /^([aeiou])(.*)/;
	return $2.$1.'ay'  if $_[0] =~ /^(.)(.*)/;
}

$original = 
"Here is a piece of text of no special account, signifying
 nothing of consequence, existing solely to demonstrate a
 useful application of the re-entrant nature of form";

($translation = $original) =~ s/([^\s,]+)/igpay_atinlay($1)/ge;

print +form 
        "||||||||||||||||||||||||||||    |||||||||||||||||||||||||||||",
        scalar form("[[[[[[[[[]]]]]]]]]",$original),
        scalar form("[[[[[[[[[[[[[[[]]]]]]]]]]",$translation);
