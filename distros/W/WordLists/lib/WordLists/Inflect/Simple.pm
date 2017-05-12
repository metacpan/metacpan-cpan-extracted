package WordLists::Inflect::Simple;
use utf8;
use strict;
use warnings;
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;

our %sTypes = (
	n=>
		[qw(
			singular
			plural
		)],
	v=>
		[qw(
			present_1st_person
			present_2nd_person
			present_3rd_person
			present_1st_person_plural
			present_2nd_person_plural
			present_3rd_person_plural

			present_participle
			past_tense
			past_participle

			infinitive
		)],
	adj=>
		[qw(
			comparative
			superlative
		)],
	
); # but everything should start as infinitive!
our $VOWELS = "aeiou";
our $iDEBUG = 5;

sub new
{
	my $class = shift;
	my $args = shift;
	$args = {} unless defined $args;
	my $self = 
	{
		special_case => [qw(man woman person child e y s of in)], # general O' -in-law
		irregular => {},
		%{$args}
	};
	bless $self, $class;
}
sub possible_special_cases
{
	return qw(man woman person child e y s of in general O' -in-law);
}
sub special_cases
{
	my $self = shift;
	my $new = shift;
	if (defined $new and ref $new eq ref [])
	{
		$self->{'special_case'} = $new;
	}
	return @{$self->{'special_case'}}
}
sub is_special_cased
{
	my ($self , $sCase ) = @_;
	return grep {$_ eq $sCase} @{$self->{'special_case'}};
}
sub add_special_case
{
	my ($self , $sCase ) = @_;
	$self->{'special_case'} = [ $sCase, @{$self->{'special_case'}} ];
}

sub remove_special_case
{
	my ($self , $sCase ) = @_;
	$self->{'special_case'} = [ grep {$_ ne $sCase} @{$self->{'special_case'}} ];
}

sub pos_from_type
{
	my ($self, $sType) = @_;
	foreach my $sPos (keys %sTypes)
	{
		if (grep {$_ eq $sType} @{$sTypes{$sPos}})
		{
			return $sPos;
		}
	}
	return '';
}
sub add_irregular_word
{
	my ($self, $args) = @_;
	my $sW = $args->{'w'};
	foreach my $key (keys %{$args})
	{
		if (grep {$_ eq $key} keys %sTypes) # key is a pos
		{
			foreach my $sType (keys %{$args->{$key}})
			{
				$self->add_irregular_inflection({w=>$sW, 'pos'=>$key, type=>$sType, inflection=>$args->{$key}{$sType}});
			}
		}
		elsif (grep { grep{$_ eq $key} @{$sTypes{$_}} } keys %sTypes)
		{
			$self->add_irregular_inflection({w=>$sW, type=>$key, inflection=>$args->{$key}});
		}
	}
	return all_irregular_inflections({w=>$sW});
}

sub add_irregular_inflection
{
	my ($self, $args) = @_;
	my $sW = $args->{'w'};
	my $sPos = $args->{'pos'};
	my $sType = $args->{'type'};
	my $sInf = $args->{'inflection'};
	$sPos ||= $self->pos_from_type($sType);
	if (!$sPos)
	{
		warn "Pos required! ($sW, ?, $sType)";
		return undef;
	}
	push (@{$self->{irregular}{$sW}{$sPos}{$sType}}, $sInf);
}

sub regular_inflection
{
	my ($self, $args) = @_;
	my $sW = $args->{'w'};
	my $sPos = $args->{'pos'};
	my $sType = $args->{'type'};
	my $sInf = $sW;
	my $three_syllables = qr/[$VOWELS]+[^$VOWELS]+[$VOWELS]+[^$VOWELS]+(?:y|[$VOWELS]+[^$VOWELS]+|[$VOWELS])$/;
	if (
		($sPos eq 'n' and $sType eq 'plural')
		or
		($sPos eq 'v' and $sType eq 'present_3rd_person')
	)
	{
		$sInf = $sW.'s';
		$sInf =~ s/siss$/eses/ if $self->is_special_cased('sis'); #thesis => theses
		$sInf =~ s/(s|x|sh|ch|z)s$/$1es/ if $self->is_special_cased('s'); 
		$sInf =~ s/([^$VOWELS])ys$/$1ies/ if $self->is_special_cased('y'); 
		$sInf =~ s/womans$/women/ if $self->is_special_cased('woman') and $sInf !~ /^[[:upper:]]/;
		$sInf =~ s/Womans$/Women/ if $self->is_special_cased('woman');
		$sInf =~ s/mans$/men/ if $self->is_special_cased('man') and $sInf !~ /^[[:upper:]]/; # German Germans
		$sInf =~ s/Mans$/Men/ if $self->is_special_cased('man'); # Man O'War
		$sInf =~ s/persons$/people/ if $self->is_special_cased('person') and $sInf !~ /^[[:upper:]]/; 
		$sInf =~ s/^Persons$/People/ if $self->is_special_cased('person'); # Person of Colour
		$sInf =~ s/childs$/children/ if $self->is_special_cased('child') and $sInf !~ /^[[:upper:]]/; # Rothschild Rothschilds
		$sInf =~ s/^Childs$/Children/ if $self->is_special_cased('child'); # Child of the 60s
	}
	elsif (
		($sPos eq 'v' and $sType eq 'past_tense')
		or
		($sPos eq 'v' and $sType eq 'past_participle')
	)
	{
		$sInf = $sW.'ed';
		$sInf =~ s/eed$/ed/ if $self->is_special_cased('e'); 
		$sInf =~ s/([^$VOWELS])yed$/$1ied/ if $self->is_special_cased('y'); 
	}
	elsif (
		($sPos eq 'v' and $sType eq 'present_participle')
	)
	{
		$sInf = $sW.'ing';
		#$sInf =~ s/([^$VOWELS])eing$/$1ing/ if $self->is_special_cased('e'); 
		$sInf =~ s/([^aeio])eing$/$1ing/ if $self->is_special_cased('e'); 
		
	}
	elsif (
		($sPos eq 'adj' and $sType eq 'comparative')
	)
	{
		
		if ($sW =~ /$three_syllables/)
		{
			return "more $sW";
		}
		else
		{
			$sInf = $sW.'er';
			$sInf =~ s/eer$/er/ if $self->is_special_cased('e'); 
			$sInf =~ s/([^$VOWELS])yer$/$1ier/ if $self->is_special_cased('y'); 
		}
	}
	elsif (
		($sPos eq 'adj' and $sType eq 'superlative')
	)
	{
		if ($sW =~ /$three_syllables/)
		{
			return "most $sW";
		}
		else
		{
			$sInf = $sW.'est';
			$sInf =~ s/([^$VOWELS])yest$/$1iest/ if $self->is_special_cased('y'); 
			$sInf =~ s/eest$/est/ if $self->is_special_cased('e'); 
		}
	}
	return $sInf;
}

sub get_irregular_inflections
{
	my ($self, $args) = @_;
	my $sW = $args->{'w'};
	my $sPos = $args->{'pos'};
	my $sType = $args->{'type'};
	my $sInf = $args->{'inflection'};
	$sPos ||= pos_from_type($sType);
	if (!$sPos)
	{
		warn "Pos required! ($sW, ?, $sType)";
		return undef;
	}
	return @{$self->{'irregular'}{$sW}{$sPos}{$sType}} if defined $self->{'irregular'}{$sW}{$sPos}{$sType};
	return undef;
}

sub irregular_inflection
{
	my ($self, $args) = @_;
	my $sInf = ${[$self->get_irregular_inflections($args)]}[0];
	unless (defined $sInf)
	{
		$sInf = $self->regular_inflection($args);
	}
	return $sInf;
}

sub phrase_inflection
{
	my ($self, $args) = @_;
	my $sPhrase = $args->{'w'};
	my $sPos = $args->{'pos'};
	
	$args->{'inflect'} ||= \&WordLists::Inflect::Simple::irregular_inflection;
	
	my @sTokens = split(/\s/, $sPhrase); # Even in "top-up card" and "Man O'War" we never want to split by /-/ or /'/. This is only an issue in irregulars anyway.
	
	if ($sPos eq 'v')
	{
		$args->{'w'} = $sTokens[0];
		$sTokens[0] = &{$args->{'inflect'}}($self, $args);
	}
	elsif ($sPos eq 'n' and $sTokens[-1]=~/^O['’]/ and defined $sTokens[-2] and $self->is_special_cased("O'"))
	{
		$args->{'w'} = $sTokens[-2];
		$sTokens[-2] = &{$args->{'inflect'}}($self, $args);
	}
	elsif ($sPos eq 'n' and $sTokens[-1]=~/^[Gg]eneral/ and defined $sTokens[-2] and $self->is_special_cased('general'))
	{
		$args->{'w'} = $sTokens[-2];
		$sTokens[-2] = &{$args->{'inflect'}}($self, $args);
	}
	elsif ($sPos eq 'n' and $sTokens[-1]=~/(.*)-in-law/ and $self->is_special_cased('-in-law'))
	{
		$args->{'w'} = $1;
		$sTokens[-1] = &{$args->{'inflect'}}($self, $args).'-in-law';
	}
	elsif ($sPos eq 'n' and $sTokens[-1] eq 'law' and defined $sTokens[-2] and $sTokens[-2] eq 'in' and defined $sTokens[-3] and $self->is_special_cased('-in-law'))
	{
		$args->{'w'} = $sTokens[-3];
		$sTokens[-3] = &{$args->{'inflect'}}($self, $args);
	}
	elsif ($sPos eq 'n' and defined $sTokens[-3] and $sTokens[-2]=~/\bof\b/ and $self->is_special_cased('of'))
	{
		$args->{'w'} = $sTokens[-3];
		$sTokens[-3] = &{$args->{'inflect'}}($self, $args);
	}
	elsif ($sPos eq 'n' and defined $sTokens[-4] and $sTokens[-3]=~/\bof\b/ and $sTokens[-2]=~/\bthe\b/ and $self->is_special_cased('of'))
	{
		$args->{'w'} = $sTokens[-4];
		$sTokens[-4] = &{$args->{'inflect'}}($self, $args);
	}
	elsif ($sPos eq 'n' and defined $sTokens[-3] and $sTokens[-2]=~/\bin\b/ and $self->is_special_cased('in'))
	{
		$args->{'w'} = $sTokens[-3];
		$sTokens[-3] = &{$args->{'inflect'}}($self, $args);
	}
	elsif ($sPos eq 'n' and defined $sTokens[-4] and $sTokens[-3]=~/\bin\b/ and $sTokens[-2]=~/\bthe\b/ and $self->is_special_cased('in'))
	{
		$args->{'w'} = $sTokens[-4];
		$sTokens[-4] = &{$args->{'inflect'}}($self, $args);
	}
	elsif ($sPos eq 'n')
	{
		$args->{'w'} = $sTokens[-1];
		$sTokens[-1] = &{$args->{'inflect'}}($self, $args);
	}
	elsif ($sPos eq 'adj' and $#sTokens==0)
	{
		$args->{'w'} = $sTokens[0];
		$sTokens[0] = &{$args->{'inflect'}}($self, $args);
	}
	elsif ($sPos eq 'adj' and $args->{'type'} eq 'comparative')
	{
		unshift @sTokens, 'more';
		return join (' ', @sTokens);
	}
	elsif ($sPos eq 'adj' and $args->{'type'} eq 'superlative')
	{
		unshift @sTokens, 'most';
		return join (' ', @sTokens);
	}
	$args->{'w'} = $sPhrase;
	return join (' ', @sTokens);
}

sub all_inflections
{
	my ($self, $args) = @_;
	my $result ={};
	my $sPos = $args->{'pos'};
	if (defined $sPos)
	{
		
		foreach my $sType (@{$sTypes{$sPos}})
		{
			$args->{'type'} = $sType;
			$result->{$sPos}{$sType} = $self->phrase_inflection($args);
		}
	}
	else
	{
		foreach (keys %sTypes)
		{
			$args->{'pos'} = $_;
			$result->{$_}=${$self->all_inflections($args)}{$_};
		}
	}
	return $result;
}
sub all_irregular_inflections
{
	my ($self, $args) = @_;
	my $result ={};
	return $result unless defined $args->{'w'};
	return $result = $self->{'irregular'}{$args->{'w'}};
}
1;

=pod

=head1 NAME

WordLists::Inflect::Simple

=head1 SYNOPSIS

	$inflector = WordLists::Inflect::Simple->new;
	$sPlural = $inflector->regular_inflection({w=>'sky', pos=>'n', type=>'plural'});
	$inflector->add_special_case('general');
	$sPlural = $inflector->phrase_inflection({w=>'Director General', pos=>'n', type=>'plural'});

=head1 DESCRIPTION

This module provides an object which can be used to generate regular and semi-regular English inflections.

By default, it comes with several defaults for semi-regular special cases - dealing with word-final 'e', 'y', and sibilants, dealing with words ending 'man'. This behaviour can be turned on and off. 

It deliberately does not deal with irregular forms, even important ones like the verb 'be'. However, it does provide an interface for user-specified irregular inflections, and it is trivial to write a wrapper module (subclass) which loads a pre-written set of inflections.

It does not deal with semi-regular patterns which require knowledge of the behaviour of individual words - for example, there is no reliable way of inspecting 'abet' and discerning that the 't' must be doubled in the present participle. Similarly, there is no attempt made to identify Latin '-us/i' plurals, as this would require making exceptions for words like 'minibus', 'omnibus', and 'octopus'. These must be entered as irregular inflections. 

=head2 Special Cases

=head3 e

Words ending in e, when given inflections like 'ed', 'er', 'est' do not get a second 'e', e.g. blue => bluer, not blue => blueer. Verbs ending in e also lose the e in the present participle, unless the e is preceded by [aeio] (e.g. argue => arguing but see => seeing).

=head3 y

Words ending in y, when given 's' inflections or 'e' inflections are subject to a conversion of the 'y' to 'i'/'ie', unless the 'y' is preceded by a vowel, e.g. sky => skies, but day => days. 

=head3 s

Words ending in sibilants (s, x, sh, ch, z), when given 's' inflections gain an 'e', e.g. 'sash'=>'sashes'.

=head3 of

When a phrase of the form X of Y is inflected as a noun, it is X rather than Y which is inflected. This also applies to the pattern X of the Y.

=head3 in

When a phrase of the form X in Y is inflected as a noun, it is X rather than Y which is inflected. This also applies to the pattern X in the Y.

=head3 general

When a phrase of the form X General is inflected as a noun, it is X rather than General which is inflected. 

=head3 O'

When a phrase of the form X O'Y is inflected as a noun, it is X rather than Y which is inflected. 

=head3 man 

Nouns ending in 'man' which do not begin with a capital are pluralised 'men' (postman => postmen but German => Germans).

=head3 woman

Nouns ending in 'woman' which do not begin with a capital are pluralised 'women'.

=head3 person

Nouns ending in 'person' which do not begin with a capital are pluralised 'people'.

=head3 child

Nouns ending in 'child' which do not begin with a capital are pluralised 'children'.

=head3 -in-law

When a phrase of the form X-in-law is inflected as a noun, it is X rather than -in-law which is inflected. 

=head2 Miscellaneous notes

There are three parts of speech which can be inflected with this, C<n>, C<v>, and C<adj>.

=head1 TODO

Improve the accessors for the special cases so a user can query the object for useful special cases to add, specify a fixed list of special cases so new cases don't affect functionality, etc.

Add pos normalisation and an interface for customising the pos normalisation routine.

Document all methods.

=head1 BUGS

English is buggy. Newspeak is doubleplusgoodlier; consider upgrading.

Some potentially unexpected results may arise, e.g. with 'man' special cased, human is incorrectly pluralised as humen, not the 'more regular' (and correct) humans.

Please use the Github issues tracker for other bugs.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
