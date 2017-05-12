package WordLists::Tag::Tagger;
use strict;
use warnings;
use utf8;
use WordLists::Common qw(/generic/);
use Lingua::EN::Tagger;
use WordLists::WordList;
use WordLists::Sense;
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;

our $AUTOLOAD;
our @ignore_pos_codes = qw(cd to prp prps sym pp pps ppr lrb rrb ppc ppl );
sub _norm_word($)
{
	my $s = shift;
	$s=~s/\.//g;
	$s=~s/\/.*//;
	$s=~s/['’]s$//;
	$s=~s/['‘’`"“”]$//;
	$s=~s/^['‘’`"“”]//;
	$s=~tr/…–\xA0\*//d;
	return lc $s;
}
sub human_pos($)
{
	my $sPos = shift;
	$sPos =~	s<^nn.*$>
				<noun>;
	$sPos =~	s<^in$>
				<preposition>;
	$sPos =~	s<^to$>
				<preposition>;
	$sPos =~	s<^jj.*$>
				<adjective>;
	$sPos =~	s<^md.*$>
				<modal verb>;
	$sPos =~	s<^vb.*$>
				<verb>;
	$sPos =~	s<^rb.*$>
				<adverb>;
	$sPos =~	s<^det$>
				<determiner>;
	$sPos =~	s<^cc$>
				<conjunction>;
	$sPos =~	s<^wrb$>
				<pronoun>;
	$sPos =~	s<^wdt$>
				<pronoun>;
	$sPos =~	s<^wp$>
				<pronoun>;
	$sPos =~	s<^prp.*$>
				<pronoun>;
	$sPos =~	s<^cd.*$>
				<number>;
	$sPos =~	s<^uh$>
				<interjection>;
	return $sPos;
}


sub new
{
	my ($class,  $args) = @_;
	$args ||={};
	my $self = {
		tagger=>Lingua::EN::Tagger->new(%$args),
	};
	bless ($self, $class);
}

1;

sub add_tags
{
	my ($self, $sMS) = @_;
	my $taggedMS = $self->{tagger}->add_tags( $sMS );
	return $taggedMS;
}

sub add_human_tags
{
	my ($self, $sMS) = @_;
	my  $sMSOUT = '';
	foreach my $sSentence (@{$self->{tagger}->get_sentences($sMS)})
	{
		$sSentence =~ tr/<>&//d;
		my $taggedSentence = $self->{tagger}->add_tags( $sSentence );
		$taggedSentence =~ s`<([a-z]+)>([^<]+)</\1>`human_pos($1) ne $1 ? qq(<span pos=").human_pos($1).qq(">$2</span>) : $2;`ge;
		$sMSOUT .= "<p>$taggedSentence</p> ";
	}
	return $sMSOUT;
}

sub get_wordlist
{
	my ($self, $sUntagged, $args) = @_;
	
	my $wl;
	if (defined $args->{'wl'} and ref $args->{'wl'} eq 'WordLists::WordList')
	{
		$wl=$args->{'wl'};
	}
	else
	{
		$wl = WordLists::WordList->new;
	}
	foreach my $sSentence (@{$self->{tagger}->get_sentences($sUntagged)})
	{
		my $taggedMS;
		$taggedMS = $self->{tagger}->add_tags( $sSentence );
		while ($taggedMS =~ m`<([a-z]+)>([^<]+)</\1>`g)
		{
			#print "\n$1\t$2";
			my $sHW = _norm_word($2);
			my $sPosCode = $1;
			my $bNext;
			foreach (@ignore_pos_codes) #
			{
				if ($sPosCode eq $_)
				{
					$bNext++;
					last;
				}
			}
			next if $bNext;
			my $sPos = human_pos($sPosCode);
			my $sense = WordLists::Sense->new();
			$sense->set_hw($sHW);
			$sense->set_pos($sPos);
			$sense->set_eg($sSentence);
			$sense->set_poscode($sPosCode);
			if (defined $args->{'callback_on_make_sense'} and ref $args->{'callback_on_make_sense'} eq ref sub{})
			{
				&{$args->{'callback_on_make_sense'}}($sense);
			}
			my @senses = $wl->get_senses_for($sense->get_hw, $sense->get_pos);
			if (@senses and !$args->{'keep_repeats'})
			{
				
			}
			else
			{
				if (defined $args->{'test_sense_before_add'} and ref $args->{'test_sense_before_add'} eq ref sub {} and !&{$args->{'test_sense_before_add'}}($sense))
				{
				}
				else
				{
					if (defined $args->{'callback_on_add_sense'} and ref $args->{'callback_on_add_sense'} eq ref sub{})
					{
						&{$args->{'callback_on_add_sense'}}($sense);
					}
					$wl->add_sense($sense);
				}
			}
		};
	}
	return $wl;
}
=pod

=head1 NAME

WordLists::Tag::Tagger

=head1 SYNOPSIS
	
	my $tagger = WordLists::Tag::Tagger->new();
	my $wl = $tagger->get_wordlist('The quick brown fox jumped over the lazy dog');

=head1 DESCRIPTION

Uses L<Lingua::EN::Tagger> to do various things with strings, chielfly to create a L<WordLists::WordList> out of a document, e.g. to use as a basis for a glossary.

=head1 METHODS

=head3 get_wordlist

Uses L<Lingua::EN::Tagger> to create a L<WordLists::WordList> out of a string (e.g. a manuscript).

L<Lingua::EN::Tagger> allows splitting into sentences, and these sentences become C<eg> fields in the L<WordLists::Sense>s generated. 

Only the first instance of each headword / part of speech combination is entered into the list, unless the third argument has a key C<keep_repeats> with a true value.

The fields populated are: C<hw>, C<pos>, C<eg>, and C<poscode>, which is the original part of speech code outputted by the tagger.

The third argument is a hashref which allows you to configure several options.

C<callback_on_add_sense> should be a coderef. It is passed the sense immediately before it is added to the wordlist, e.g. if you want to add a unit. 

C<callback_on_make_sense> should be a coderef. It is passed the sense before the wordlist is tested for inclusion. This is an opportunity to further normalise parts of speech. 

C<keep_repeats> is a flag, which, if set, prevents the code from removing repetitions.

=head1 TODO

C<ignore> is a wordlist or arrayref whose elements are L<WordLists::Sense> objects or plain hashrefs of the form C<< {hw=>'head', pos =>'n'} >>, or headwords as strings. If these words are found, they are not added to the list. (not yet implemented!)

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut