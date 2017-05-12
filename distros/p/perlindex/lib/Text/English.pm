#!/usr/bin/perl
#                              -*- Mode: Perl -*- 
# Author          : Ian Phillipps
# Last Modified On: Sun May  2 15:35:33 2004
# Language        : CPerl

package Text::English;

$VERSION = $VERSION = '0.01';

sub stem {
    my @parms = @_;
    foreach( @parms ) {
	$_ = lc $_;

	# Step 0 - remove punctuation
	s/'s$//; s/^[^a-z]+//; s/[^a-z]+$//;
	next unless /^[a-z]+$/;

	# step1a_rules
	if( /[^s]s$/ ) { s/sses$/ss/ || s/ies$/i/ || s/s$// }
       
	# step1b_rules. The business with rule==106 is embedded in the
	# boolean expressions here.
	(/[aeiouy][^aeiouy].*eed$/ && s/eed$/ee/ ) || 
	    ( s/([aeiou].*)ed$/$1/ || s/([aeiouy].*)ing$/$1/ ) &&
	    ( # step1b1_rules
		s/at$/ate/	|| s/bl$/ble/	|| s/iz$/ize/	|| s/bb$/b/	||
		s/dd$/d/	|| s/ff$/f/	|| s/gg$/g/	|| s/mm$/m/	||
		s/nn$/n/	|| s/pp$/p/	|| s/rr$/r/	|| s/tt$/t/	||
		s/ww$/w/	|| s/xx$/x/	||
		# This is wordsize==1 && CVC...addanE...
		s/^[^aeiouy]+[aeiouy][^aeiouy]$/$&e/
	    )
#DEBUG	    && warn "step1b1: $_\n"
	    ;
	# step1c_rules
#DEBUG	warn "step1c: $_\n" if
	s/([aeiouy].*)y$/$1i/;

	# step2_rules

	if (	s/ational$/ate/	|| s/tional$/tion/	|| s/enci$/ence/	||
		s/anci$/ance/	|| s/izer$/ize/		|| s/iser$/ise/		||
		s/abli$/able/	|| s/alli$/al/		|| s/entli$/ent/	||
		s/eli$/e/	|| s/ousli$/ous/	|| s/ization$/ize/	||
		s/isation$/ise/	|| s/ation$/ate/	|| s/ator$/ate/		||
		s/alism$/al/	|| s/iveness$/ive/	|| s/fulnes$/ful/	||
		s/ousness$/ous/	|| s/aliti$/al/		|| s/iviti$/ive/	||
		s/biliti$/ble/
	    ) {
	    my ($l,$m) = ($`,$&);
#DEBUG	    warn "step 2: l=$l m=$m\n";
	    $_ = $l.$m unless $l =~ /[^aeiou][aeiouy]/;
	}
	# step3_rules
	if (	s/icate$/ic/	|| s/ative$//	|| s/alize$/al/	||
		s/iciti$/ic/	|| s/ical$/ic/	|| s/ful$//	||
		s/ness$//
	    ) {
	    my ($l,$m) = ($`,$&);
#DEBUG	    warn "step 3: l=$l m=$m\n";
	    $_ = $l.$m unless $l =~ /[^aeiou][aeiouy]/;
	}

	# step4_rules
	if (	s/al$//		|| s/ance$//	|| s/ence$//	|| s/er$//	||
		s/ic$//		|| s/able$//	|| s/ible$//	|| s/ant$//	||
		s/ement$//	|| s/ment$//	|| s/ent$//	|| s/sion$/s/	||
		s/tion$/t/	|| s/ou$//	|| s/ism$//	|| s/ate$//	||
		s/iti$//	|| s/ous$//	|| s/ive$//	|| s/ize$//	||
		s/ise$//
	    ) {
	    my ($l,$m) = ($`,$&);
	# Look for two consonant/vowel transitions
	# NB simplified...
#DEBUG	    warn "step 4: l=$l m=$m\n";
	    $_ = $l.$m unless $l =~ /[^aeiou][aeiouy].*[^aeiou][aeiouy]/;
	}

	# step5a_rules
#DEBUG	warn("step 5a: $_\n") &&
	s/e$// if ( /[^aeiou][aeiouy].*[^aeiou][aeiouy].*e$/ ||
		( /[aeiou][^aeiouy].*e/ && ! /[^aeiou][aeiouy][^aeiouwxy]e$/) );

	# step5b_rules
#DEBUG	warn("step 5b: $_\n") &&
	s/ll$/l/ if /[^aeiou][aeiouy].*[^aeiou][aeiouy].*ll$/;

	# Cosmetic step 
	s/(.)i$/$1y/;
    }
    @parms;
}

1;

__END__

=head1 NAME

Text::English - Porter's stemming algorithm

=head1 SYNOPSIS

    use Text::English;
    @stems = Text::English::stem( @words );

=head1 DESCRIPTION

This routine applies the Porter Stemming Algorithm to its parameters,
returning the stemmed words.
It is derived from the C program "stemmer.c"
as found in freewais and elsewhere, which contains these notes:

   Purpose:    Implementation of the Porter stemming algorithm documented 
               in: Porter, M.F., "An Algorithm For Suffix Stripping," 
               Program 14 (3), July 1980, pp. 130-137.
   Provenance: Written by B. Frakes and C. Cox, 1986.

I have re-interpreted areas that use Frakes and Cox's "WordSize"
function. My version may misbehave on short words starting with "y",
but I can't think of any examples.

The step numbers correspond to Frakes and Cox, and are probably in
Porter's article (which I've not seen).
Porter's algorithm still has rough spots (e.g current/currency, -ings words),
which I've not attempted to cure, although I have added
support for the British -ise suffix.

=head1 NOTES

This is version 0.1. I would welcome feedback, especially improvements
to the punctuation-stripping step.

=head1 AUTHOR

Ian Phillipps <ian@unipalm.pipex.com>

=head1 COPYRIGHT

Copyright Public IP Exchange Ltd (PIPEX).
Available for use under the same terms as perl.

=cut

