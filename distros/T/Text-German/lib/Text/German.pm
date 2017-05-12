#!/usr/bin/perl
#                              -*- Mode: Perl -*- 
# Word.pm -- 
# ITIID           : $ITI$ $Header $__Header$
# Author          : Ulrich Pfeifer
# Created On      : Thu Feb  1 13:57:42 1996
# Last Modified By: Ulrich Pfeifer
# Last Modified On: Sun Apr  3 12:17:56 2005
# Language        : Perl
# Update Count    : 70
# Status          : Unknown, Use with caution!
#

package Text::German;

$VERSION = $VERSION = 0.06;
use Text::German::Util;
require Text::German::Adjektiv;
require Text::German::Ausnahme;
require Text::German::Endung;
require Text::German::Regel;
require Text::German::Verb;
require Text::German::Vorsilbe;
require Text::German::Cache;

sub partition {
    my $word = shift;
    my $vorsilbe = Text::German::Vorsilbe::max_vorsilbe($word);
    my $vl       = length($vorsilbe||'');
    my $endung   = Text::German::Endung::max_endung(substr($word,$vl));
    my $el       = length($endung||'');
    my $l        = length($word);

    return ($vorsilbe, substr($word, $vl, $l-$vl-$el), $endung);
}

sub reduce {
    my $word        = shift;
    my $satz_anfang = shift;
    my @word = partition($word);
    my @tmp;

    printf "INIT %s\n", join ':', @word if $debug;
    $word[0] ||= '';
    $word[2] ||= '';

    my $a = Text::German::Ausnahme::reduce(@word);
    return($a) if defined $a;

    my $c = wordclass($word, $satz_anfang);

    unless ($c&$FUNNY || $word[2]) {
      return $word[1];
    }
    if ($c & $VERB) {
	@tmp = Text::German::Verb::reduce(@word);
	if ($#tmp) {
	    @word = @tmp;
	    printf "VERB %s\n", join ':', @word if $debug;
            return($word[1].'en');
	}
    }
    if ($c & $ADJEKTIV) {
	@tmp = Text::German::Adjektiv::reduce(@word);
	if ($#tmp) {
	    @word = @tmp;
	    printf "VERB %s\n", join ':', @word if $debug;
            return($word[1]);
	}
    }
    @tmp = Text::German::Regel::reduce(@word);
    if ($#tmp) {
	@word = @tmp;
	printf "REGEL %s\n", join ':', @word if $debug;
    }
    #return join ':', @word;
    return $word[0].$word[1]; # vorsilbe wieder anhaengen
}

# Do not use this! 
my $cache;

sub cache_reduce {
  unless ($cache) {
    $cache = Text::German::Cache->new(Verbose  => 0,
                                      Function => sub {reduce($_[0], 1); },
                                      Gc       => 1000,
                                      Hold     => 600,
                                     );
  }
  $cache->get(@_);
}

# This is a hoax!
sub stem {
  my $word        = shift;
  my $gf          = reduce($word, @_);
  my @word = partition($gf);

  return $word[1];
}

1;
