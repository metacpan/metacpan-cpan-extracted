package WordLists::Common;
use strict;
use warnings;
use Unicode::Normalize; #provides NFD
use utf8;
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;

our $AUTOLOAD;
require Exporter;
our @ISA       = qw (Exporter);
our @EXPORT    = ();
our @EXPORT_OK = qw(
	pretty_doubles
	pretty_singles
	pretty_endash
	norm_spacing
	custom_norm
	generic_norm_hw
	generic_norm_pos
	generic_minimal_pos
	uniques
	@sPosWords
	@sDefaultAttList
	@sDefiningAttlist
	@sParsingParameters
	reverse_punct
);
our @sDefaultAttList = qw(hw pos def eg);
our @sDefiningAttlist = qw(hw pos);
our @sParsingParameters = qw(is_header field_sep attlist default_attlist header_marker);
our @sPosWords = (qw(
	n
	noun
	v
	verb
	adj
	adjective
	adv
	advb
	adverb
	conj
	conjunction
	excl
	exclamation
	expression
	pref
	prefix
	suffix
	det
	determiner
	quant
	quantifier
	postmodifier
	predeterminer
	abbreviation
	pv
	mv
	auxiliary
	aux
	prep
	preposition
	number
	ordinal
	cardinal
	
),
	'ordinal number',
	'cardinal number',
	'plural noun',
	'compound noun',
	'phrasal verb',
	'modal verb',
	'auxiliary verb',
);
sub pretty_doubles($)
{
	my $s = shift;
	$s =~ s/[“"”]/"/g;
	$s =~ s/"$/”/g;
	$s =~ s/^"/“/g;
	$s =~ s/"([\s\t\r\n])/”$1/g;
	$s =~ s/([\s\t\r\n])"/$1“/g;
	$s =~ s/([\(\{\[])"/$1“/g;
	$s =~ s/"([\)\}\]])/”$1/g;
	$s =~ s/([\w\.\?\!])"/$1”/g;
	$s =~ s/"/“/g;
	return $s;
}
sub reverse_punct ($)
{
	my $s = shift;
	my %sReversal = (qw`
		( )
		[ ]
		{ }
		< >
		‘ ’
		“ ”
		‹ ›
		« »
		¡ !
		¿ ?
	`);
	if (defined $sReversal{$s})
	{
		return $sReversal{$s};
	}
	foreach (qw`< [ { (`)
	{
		my $sToFind = quotemeta ($_) . "([^" . quotemeta ($sReversal{$_}) . "]+)". quotemeta $sReversal{$_};
		if ($s =~ m/^$sToFind$/)
		{
			my $sR = $s;
			$sR =~ s/^$sToFind/$_\/$1$sReversal{$_}/g;
			return $sR;
		}
	}
	return $s;
}
sub pretty_singles($)
{
	my $s = shift;
	$s =~ s/[‘'’]/'/g;
	$s =~ s/'$/’/g;
	$s =~ s/^'/‘/g;
	$s =~ s/'([\s\t\r\n])/’$1/g;
	$s =~ s/([\s\t\r\n])'/$1‘/g;
	$s =~ s/([\(\{\[])'/$1‘/g;
	$s =~ s/'([\)\}\]])/’$1/g;
	$s =~ s/([\w\.\?\!])'/$1’/g;
	$s =~ s/'/“/g;
	return $s;
}

sub pretty_endash($)
{
	my $s = shift;
	$s =~ s/([\s\t\r\n])-([\s\t\r\n])/$1–$2/g;
	$s =~ s/([\s\t\r\n])-$/$1–/g;
	$s =~ s/^-([\s\t\r\n])/–$1/g;
	return $s;
}

sub norm_spacing($)
{
	my $s = shift;
	$s =~ s/^\s+//;
	$s =~ s/\s+$//;
	$s =~ s/\s+/ /;
	return $s;
}

sub custom_norm
{
	my $s = shift;
	my $args = shift;
	return $s unless ref $args eq ref {};
	$s = lc $s if $args->{'lc'};
	$s = uc $s if $args->{'uc'};
	if ($args->{'trim_space'})
	{
		$s =~ s/^\s+//;
		$s =~ s/\s+$//;
		$s =~ s/[\t\r\n\s]+/ /g;
	}
	$s =~ s/\bsb\b/someone/g if $args->{'sb'};
	$s =~ s/\bsth\b/something/g if $args->{'sth'};
	$s =~ s/\(.*\)//g if $args->{'brackets'} eq 'kill';
	$s =~ tr/()//d if $args->{'brackets'} eq 'ignore';
	$s =~ s/\[.*\]//g if $args->{'squares'} eq 'kill';
	$s =~ tr/[]//d if $args->{'squares'} eq 'ignore';
	if ($args->{'accents'})
	{
		$s = NFD($s);    # These two lines use Unicode::Normalize::NFD to 
		$s =~ s/\pM//og; # remove accents but keep the underlying characters
	}
	
	$s =~ s/[^[:alpha:][:digit:]]//g if $args->{'alnum_only'};
		# can't and can`t should match. So, unfortunately, does cant
	$s =~ s/_//g if $args->{'alnum_only'};
	return $s;
}

sub generic_norm_hw($)
{
	my $s = lc shift;
	$s =~ s/\(.*\)//g;
	$s =~ s/\bsb\b/someone/g;
	$s =~ s/\bsth\b/something/g;
	$s =~ s/^the //g;
	$s = NFD($s);    # These two lines use Unicode::Normalize::NFD to 
	$s =~ s/\pM//og; # remove accents but keep the underlying characters
	$s =~ s/[^[:alpha:][:digit:]]//g; 
		# can't and can`t should match. So, unfortunately, does cant
	$s =~ s/_//g;
	return $s;
}

sub generic_norm_pos($)
{
	my $sPos = lc shift;
	$sPos =~ 	tr/\-\t\r\n \./     /;
	
	$sPos = norm_spacing ($sPos);
	
	$sPos =~	s<\b(pl|plural)\b>
				<plural>;
				
	$sPos =~	s<\b(comp|compound)\b>
				<compound>;
				
	$sPos =~	s<\b(n|noun)\b>
				<noun>;
	
	$sPos =~	s<\b(a|adj|adjective)\b>
				<adjective>;
	
	$sPos =~	s<\b(adv|advb|adverb)\b>
				<adverb>;

	$sPos =~	s<\b(preposition|prep)\b>
				<preposition>;
				
	$sPos =~	s<\b(quant|quantifier|q)\b>
				<quantifier>;
				
	$sPos =~	s<\b(pre)(det|determiner|d)\b>
				<$1determiner>;
	
	$sPos =~	s<\b(pronoun|pron)\b>
				<pronoun>;

	$sPos =~	s<\b(v|verb)\b>
				<verb>;

	$sPos =~	s<\b(phr|phrase)\b>
				<phrase>;
			
	$sPos =~	s<\b(exp|expr|expression)\b>
				<phrase>;
				
	$sPos =~	s<\b(mod|modal)\b>
				<modal>;

	$sPos =~	s<\bphrase\s+verb\b>
				<phrasal verb>;	
	
	$sPos =~	s<\bp\s*verb\b>
				<phrasal verb>;		

	$sPos =~	s<\b(prefix|pref)\b>
				<prefix>;
	
	$sPos =~	s<\b(suffix|suff)\b>
				<suffix>;
	
	$sPos =~	s<\b(short|abbreviated|abbreviation|abbrev|abbr)( form)?\b>
				<abbreviation>;
	
	$sPos =~	s<\b(conj|conjunction)\b>
				<conjunction>;
		
	$sPos =~	s<\b(int|interj|inter|interjection)\b>
				<interjection>;
				
	$sPos =~	s<\b(ex|excl|exclam|exclamation)\b>
				<exclamation>;
			
	return $sPos;
}


sub generic_minimal_pos($)
{
	my $sPos = generic_norm_pos(shift);
	
	$sPos =~	s<(adverb)>
				<adv>;
	$sPos =~	s<(adjective)>
				<adj>;
	$sPos =~	s<(phrasal)>
				<p>;
	$sPos =~	s<(modal)>
				<>;
	$sPos =~	s<(verb)>
				<v>;
	$sPos =~	s<(noun)>
				<n>;
	$sPos =~	s<(adjective)>
				<adj>;
	$sPos =~	s<(preposition)>
				<prep>;
	$sPos =~	s<(exclamation)>
				<excl>;
	$sPos =~tr/ //d;
	return $sPos;
}

sub uniques
{
	my %bSeen;
	return grep {$bSeen{$_}++; $bSeen{$_} ==1;} @_;
}

1;


=pod

=head1 NAME

WordLists::Common

=head1 SYNOPSIS

	use WordLists::Common qw(pretty_doubles pretty_singles);
	print pretty_doubles (pretty_singles (
			qq{"That's right," she said, "I was told to 'get lost!'".}
		) );
	
=head1 DESCRIPTION	

This provides common functions and values of relevance to wordlists - such as normalising parts of speech and typographic dashes and quotes. Exportable functions and values include:

=over

=item *
C<@sPosWords>, a list of things which look like parts of speech (to help parsing things like "head verb", "head up", "head noun")

=item *
A function C<pretty_endash> replacing space + hyphen + space with space + en-dash + space.

=item *	
A function C<pretty_doubles> replacing double quotes with 'smart' double quotes.

=item *	
A function C<pretty_singles> replacing apostrophe/single-quote with 'smart' single quotes.
	
=item *	
A function C<norm_spacing>

=item *	
A function C<custom_norm> which takes several options:

=over

=item *	
C<lc> - if true, lowercases the string.

=item *	
C<uc> - if true, uppercases the string. Overrides C<lc>.

=item *	
C<trim_space> - if true, removes initial and final space, and also condenses repeating white space to a single C<\x20>.

=item *	
C<alnum_only> - if true, removes characters other than alphabetic ones or digits.

=item *	
C<brackets> - if this is 'kill', removes the contents of any C<()> brackets; if 'ignore', removes the brackets themselves.

=item *	
C<squares> - if this is 'kill', removes the contents of any C<[]> brackets; if 'ignore', removes the brackets themselves. 

=item *	
C<accents> - if true, removes accents and modifier characters from letters.

=item *	
C<sb> - if true, replaces 'sb' with 'someone'.

=item *	
C<sth> - if true, replaces 'sth' with 'something'.

=back

=item *	
A function C<generic_norm_hw> which returns a word without accents or characters other than [a-z0-9].

=item *
A function C<generic_norm_pos> for normalising parts of speech so that 'v' and 'verb' match.

=item *	
A function C<generic_minimal_pos> which will normalise parts of speech and reduce them to 'minimal' ones.

=item *	
A function C<uniques> which will reduce a list to the unique members.

=back

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
