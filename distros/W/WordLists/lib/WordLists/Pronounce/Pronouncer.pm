package WordLists::Pronounce::Pronouncer;
use strict;
use warnings;
use utf8;
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;

sub new
{
	my ($class, $args) = @_;
	$args = {} unless defined $args;
	my $self = {
		cleaner   => \&_default_clean,
		cb_word   => undef,
		cb_phrase => undef,
		cb_fail   => sub{warn "$_[1] not found\n"; return 'X';},
		%{$args}
	};
	unless (defined $self->{'lookup'})
	{
		warn ('No lookup set for '.$class);
		
		# 
	}
	bless $self, $class;
}
sub lookup
{
	my ($self, $new) = @_;
	$self->{'lookup'} = $new if defined $new;
	return $self->{'lookup'};
}
sub clean
{
	my ($self, $word, $args) = @_;
	&{$self->{'cleaner'}}($self,$word,$args);
}
sub _default_clean
{
	my ($self, $word, $args) = @_;
	$word =~ s/\([^)]*\)//g;
	$word =~ s/^\*//;
	$word =~ s/^\s+//;
	$word =~ s/\s+$//;
	$word =~ s/[’']s\b//s;
	$word =~ s/s'\b/s/;
	$word =~ tr{/’.?",…+;:’‘}{ }d;
	$word =~ s/\s+/ /g;
	$word =~ s/^'//;
	$word =~ s/'$//;
	$word = lc $word;
	return $word;
}
sub pronounce_phrase
{
	my ($self, $word, $args) = @_;
	my $field = $args->{'field'};
	$field ||= $self->{'field'};
	warn ('Source field must be defined!') unless ($field);
	my $lookup = $self->lookup;
	my $ipa="";
	$word = $self->clean($word, $args);
	my @senses = grep {$_->get($field)} $lookup->get_senses_for($word);
	return "" if ($word eq "");
	my @ipaout = ();
	if (@senses) # if the whole input string matches
	{
		$ipa = $senses[0]->get($field);
		push @ipaout, $ipa;
	}
	else # if the whole input string does not match, try splitting and pronouncing each component
	{
		my @words = split(/[- ?]+/, $word);
		if ($#words > 0) 
		{
			foreach (@words) 
			{
				push @ipaout, $self->pronounce_phrase($_, {%$args,(as_word=>1)});
			}
		}
		else # if non-matching input string is a single word, fail. 
		{
			if (defined $self->{'cb_fail'} )
			{
				if (ref ($self->{'cb_fail'}) eq ref (sub {}))
				{
					return &{$self->{'cb_fail'}}($self, $word, $args);
				}
				elsif (ref ($self->{'cb_fail'}) eq ref (''))
				{
					return $self->{'cb_fail'};
				}
				else 
				{
					return '';
					# Don't return undef, as this will probably break string concatenation.
				}
			}
		}
	}
	my $out = join(" ", @ipaout) ;
	if (defined $self->{'cb_word'} and $args->{'as_word'}) # Callback for processing string as a word
	{
		$out = &{$self->{'cb_word'}}($self, $out, $args);
	}
	elsif (defined $self->{'cb_phrase'} and !$args->{'as_word'}) # Callback for processing string as a phrase
	{
		$out = &{$self->{'cb_phrase'}}($self, $out, $args) ;
	}
  	return $out;
}

return 1;

=pod

=head1 NAME

WordLists::Pronounce::Pronouncer

=head1 SYNOPSIS

	my $pronouncer = WordLists::Pronounce::Pronouncer->new({ lookup => $here_is_one_i_prepared_earlier });
	$ipa = $pronouncer->pronounce_phrase('tomato stew', {field=>'uspron'});

=head1 DESCRIPTION	

Allows the user to create and configure a pronouncing object which will accept strings and have a guess at their IPA transcription, based on a pre-generated list of pronunciations.

The user must specify a lookup object containing this list. 

=head1 TODO

Write and implement an API for reading several pronunciations and comparing them (possibly once the whole phrase has been put together).

Try to guess stress for compounds based on a list of compounds and/or at least making sure each word has stress. (This might be impossible to do meaningfully)

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut