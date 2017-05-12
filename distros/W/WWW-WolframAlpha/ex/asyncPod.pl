#!/usr/bin/perl

use warnings;
use strict;

use WWW::WolframAlpha;

# Instantiate WA object with your appid.
my $wa = WWW::WolframAlpha->new (
    appid => 'XXX',
);

# Send any inputs paramters in input hash (unescaped).
my $asyncPod = $wa->asyncPod(
    'url' => 'http://www1.wolframalpha.com/api/v1/asyncPod.jsp?id=MSP107197cib8g3egi8a1000002a6bg145h6da7f9b&s=29',
    );

# Error contacting WA.
if ($wa->error) {
    print "WWW::WolframAlpha error: ", $wa->errmsg , "\n" if $wa->errmsg;

} elsif (!$asyncPod->error) {

    print "\n\nPod title: ", $asyncPod->title, "\n";
    print "Scanner: ", $asyncPod->scanner, "\n";
    print "Position: ", $asyncPod->position, "\n";
    
    # Associated with format='html'.
    print "Markup: ", $asyncPod->markup, "\n" if $asyncPod->markup;
    
    # Associated with async='true'.
    print "Async: ", $asyncPod->async, "\n" if $asyncPod->async;
    
    print "Numsubpods: ", $asyncPod->numsubpods, "\n" if $asyncPod->numsubpods;
    foreach my $subpod (@{$asyncPod->subpods}) {
	print "  Subpod\n";
	print '    plaintext: ', $subpod->plaintext, "\n" if $subpod->plaintext;
	print '    title: ', $subpod->title, "\n" if $subpod->title;
	print '    minput: ', $subpod->minput, "\n" if $subpod->minput;
	print '    moutput: ', $subpod->moutput, "\n" if $subpod->moutput;
	print '    mathml: ', $subpod->mathml, "\n" if $subpod->mathml;
	print '    img: ', $subpod->img, "\n" if $subpod->img;
    }
    
    if ($asyncPod->states->count) {
	print "  States\n";
	foreach my $state (@{$asyncPod->states->state}) {
	    print "    name: ", $state->name, "\n";
	}
	
	foreach my $statelist (@{$asyncPod->states->statelist}) {
	    print "    statelist: ", $statelist->value, "\n";
	    foreach my $state (@{$statelist->state}) {
		print "      name: ", $state->name, "\n";
	    }
	}
    }
    
    # Associated with format='sound'.
    if ($asyncPod->sounds->count) {
	print "  Sounds\n";
	foreach my $sound (@{$asyncPod->sounds->sound}) {
	    print "    Sound: ", $sound->url, "\n";
	    print "      type: ", $sound->type, "\n";
	}
    }
    
    if ($asyncPod->infos->count) {
	print "  Infos\n";
	foreach my $info (@{$asyncPod->infos->info}) {
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
    print "Error ", $asyncPod->error->code, ": ", $asyncPod->error->msg, "\n";
}


