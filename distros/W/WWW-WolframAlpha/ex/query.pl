#!/usr/bin/perl

use warnings;
use strict;

use WWW::WolframAlpha;

# Instantiate WA object with your appid.
my $wa = WWW::WolframAlpha->new (
    appid => 'XXX',
);

# Send any inputs paramters in input hash (unescaped).
my $query = $wa->query(
#    'input' => '5 km to m',
#    'input' => 'age of clinton',
#    'input' => '5:30pm cst in edt',
    'input' => '1-1',
#    'input' => 'sinh(0)',
#    'format' => 'sound',
#    'format' => 'html',
#    'podstate' => 'More digits',
#    'async' => 'true',
#    'assumption' => '*F.DopplerShift.vs-_6.5+m%2Fs',
    'scantimeout' => 3,
    'podtimeout' => 3,
    'format' => 'plaintext,image',
#    'podtitle' => 'Result',
    );


if ($query->success) {

    print "Datatypes: ", $query->datatypes, "\n" if $query->datatypes;
    print "Timing: ", $query->timing, "\n" if $query->timing;
    print "Parsetiming: ", $query->parsetiming, "\n" if $query->parsetiming;
    print "Timedout: ", $query->timedout, "\n" if $query->timedout;

    # Associated with format='html'.
    print "CSS: ", $query->css, "\n" if $query->css;
    print "Scripts: ", $query->scripts, "\n" if $query->scripts;
    
    print "\n\n\nNumpods: ", $query->numpods, "\n";
    foreach my $pod (@{$query->pods}) {
	if (!$pod->error) {

	    print "\n\nPod title: ", $pod->title, "\n";
	    print "Scanner: ", $pod->scanner, "\n";
	    print "Position: ", $pod->position, "\n";
	    
	    # Associated with format='html'.
	    print "Markup: ", $pod->markup, "\n" if $pod->markup;
	    
	    # Associated with async='true'.
	    print "Async: ", $pod->async, "\n" if $pod->async;
	    
	    print "Numsubpods: ", $pod->numsubpods, "\n" if $pod->numsubpods;
	    foreach my $subpod (@{$pod->subpods}) {
		print "  Subpod\n";
		print '    plaintext: ', $subpod->plaintext, "\n" if defined $subpod->plaintext;
		print '    title: ', $subpod->title, "\n" if $subpod->title;
		print '    minput: ', $subpod->minput, "\n" if $subpod->minput;
		print '    moutput: ', $subpod->moutput, "\n" if $subpod->moutput;
		print '    mathml: ', $subpod->mathml, "\n" if $subpod->mathml;
		print '    img: ', $subpod->img, "\n" if $subpod->img;
	    }
	    
	    if ($pod->states->count) {
		print "  States\n";
		foreach my $state (@{$pod->states->state}) {
		    print "    name: ", $state->name, "\n";
		}
		
		foreach my $statelist (@{$pod->states->statelist}) {
		    print "    statelist: ", $statelist->value, "\n";
		    foreach my $state (@{$statelist->state}) {
		    print "      name: ", $state->name, "\n";
		    }
		}
	    }
	    
	    # Associated with format='sound'.
	    if ($pod->sounds->count) {
		print "  Sounds\n";
		foreach my $sound (@{$pod->sounds->sound}) {
		    print "    Sound: ", $sound->url, "\n";
		    print "      type: ", $sound->type, "\n";
		}
	    }
	    
	    if ($pod->infos->count) {
		print "  Infos\n";
		foreach my $info (@{$pod->infos->info}) {
		    print "    Info\n";
		    print "      text: ", $info->text, "\n" if $info->text;
		    
		    foreach my $link (@{$info->link}) {
			print "      link: ", $link->url, "\n";
			print "        title: ", $link->title, "\n" if $link->title;
			print "        text: ", $link->text, "\n" if $link->text;
		    }
		    
		    if ($info->units->count) {
			print "      units img: ", $info->units->img, "\n" if $info->units->img;
			foreach my $unit (@{$info->units->unit}) {
			    print "      unit: ", $unit->short, "\n";
			    print "        long: ", $unit->long, "\n";
			}
		    }
		}
	    }
	    
	} else {
	    print "Error ", $pod->error->code, ": ", $pod->error->msg, "\n";
	}
    }

	
    if ($query->assumptions->count) {
	print "\n\nAssumptions\n";
	foreach my $assumption (@{$query->assumptions->assumption}) {
	    print "\n  type: ", $assumption->type, "\n";
	    print "  word: ", $assumption->word, "\n" if $assumption->word;
	    foreach my $value (@{$assumption->value}) {
		print '    ', $value->name, ', ', $value->desc, ' (', $value->input, ') ', "\n";
		print '     valid: ', $value->valid, "\n" if defined $value->valid;
	    }
	}
    }
    
    if ($query->sources->count) {
	print "\n\nSources\n";
	foreach my $source (@{$query->sources->source}) {
	    print "  url: ", $source->url, "\n";
	    print "  text: ", $source->text, "\n" if $source->text;
	}
    }
	
    if ($query->warnings->count) {
	print "\nWarnings\n";
	print "  delimiters: ", $query->warnings->delimiters, "\n" if $query->warnings->delimiters;
	
	foreach my $spellcheck (@{$query->warnings->spellcheck}) {
	    print "  Spellcheck word: ", $spellcheck->word, "\n";
	    print "    suggestion: ", $spellcheck->suggestion, "\n" if $spellcheck->suggestion;
	    print "    text: ", $spellcheck->text, "\n" if $spellcheck->text;
	}
	
    }
    

# No success, but no error either.
} elsif (!$query->error) {
    print "No results.\n";

    if ($query->didyoumeans->count) {
	foreach my $didyoumean (@{$query->didyoumeans->didyoumean}) {
	    print "  Did you mean: ", $didyoumean->text, "\n"
	}
    }


# Error contacting WA.
} elsif ($wa->error) {
    print "WWW::WolframAlpha error: ", $wa->errmsg , "\n" if $wa->errmsg;


# Error returned by WA.    
} elsif ($query->error) {
    print "WA error ", $query->error->code, ": ", $query->error->msg, "\n";

}


