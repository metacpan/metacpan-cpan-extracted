#!/usr/bin/perl

use warnings;
use strict;

use WWW::WolframAlpha;

# Instantiate WA object with your appid.
my $wa = WWW::WolframAlpha->new (
    appid => 'XXX',
);

# Send any inputs paramters in input hash (unescaped).
my $validatequery = $wa->validatequery(
    'input' => 'pi',
    'scantimeout' => 3,
    );


if ($validatequery->success) {
    print "Timing: ", $validatequery->timing, "\n" if $validatequery->timing;
    print "Parsetiming: ", $validatequery->parsetiming, "\n" if $validatequery->parsetiming;

    if ($validatequery->assumptions->count) {
	print "\n\nAssumptions\n";
	foreach my $assumption (@{$validatequery->assumptions->assumption}) {
	    print "\n  type: ", $assumption->type, "\n";
	    print "  word: ", $assumption->word, "\n" if $assumption->word;
	    foreach my $value (@{$assumption->value}) {
		print '    ', $value->name, ', ', $value->desc, ' (', $value->input, ') ', "\n";
		print '     valid: ', $value->valid, "\n" if defined $value->valid;
	    }
	}
    }
    
    if ($validatequery->warnings->count) {
	print "\nWarnings\n";
	print "  delimiters: ", $validatequery->warnings->delimiters, "\n" if $validatequery->warnings->delimiters;
	
	foreach my $spellcheck (@{$validatequery->warnings->spellcheck}) {
	    print "  Spellcheck word: ", $spellcheck->word, "\n";
	    print "    suggestion: ", $spellcheck->suggestion, "\n" if $spellcheck->suggestion;
	    print "    text: ", $spellcheck->text, "\n" if $spellcheck->text;
	}
	
    }
    

# No success, but no error either.
} elsif (!$validatequery->error) {
    print "No results.\n";


# Error contacting WA.
} elsif ($wa->error) {
    print "WWW::WolframAlpha error: ", $wa->errmsg , "\n" if $wa->errmsg;


# Error returned by WA.    
} elsif ($validatequery->error) {
    print "WA error ", $validatequery->error->code, ": ", $validatequery->error->msg, "\n";

}


