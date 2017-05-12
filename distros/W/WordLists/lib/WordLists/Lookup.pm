package WordLists::Lookup;
use strict;
use warnings;
use utf8;
use WordLists::Sense;
use WordLists::Common qw(/generic/);
our $AUTOLOAD;
our $UNPACKAGE_SENSES = 1;
sub new
{
	my ($class,  $args) = @_;
	my $self = {
		'index' => [],
		'norm_hw' => \&generic_norm_hw,
		'norm_pos' => \&generic_norm_pos,
	};
	if ( ref $args eq ref {})
	{
		foreach (qw(norm_hw norm_pos dicts))
		{
			if (defined $args->{$_})
			{
				$self->{$_} = $args->{$_};
			}
		}
	}
	else 
	{
		warn ('Failed to create '. $class . ' (hashref expected as argument to function new; found '.$args.')');
		return undef;
	}
	bless ($self, $class);
	$self->index_dict($_) foreach @{$self->{'dicts'}};
	return $self if @{$self->{'dicts'}};
	warn ('Failed to create '. $class);
	return undef;
}

sub norm_hw
{
	my ($self, $sHW) = @_;
	return &{$self->{'norm_hw'}}($sHW);
}
sub norm_pos
{
	my ($self, $sPos) = @_;
	return &{$self->{'norm_pos'}}($sPos);
}
sub get_senses_for
{
	my ($self, $sHW, $sPos) = @_;
	$sHW = $self->norm_hw($sHW);
	my @senses;
	if (defined $sPos and ($sPos or $self->{'significant_empty_pos'}))
	{
		$sPos = $self->norm_pos($sPos);
		DICT: foreach my $iDict (0..$#{$self->{'index'}})
		{
			if (defined $self->{'index'}[$iDict]{$sHW}{$sPos})
			{
				@senses = @{$self->{'index'}[$iDict]{$sHW}{$sPos}} ;
				last DICT;
			}
		}
	}
	else
	{
		DICT: foreach my $iDict (0..$#{$self->{'index'}})
		{
			if (defined $self->{'index'}[$iDict]{$sHW})
			{
				foreach my $sPos (keys %{$self->{'index'}[$iDict]{$sHW}})
				{
					push @senses, @{$self->{'index'}[$iDict]{$sHW}{$sPos}};
				}
				last DICT if @senses;
			}
		}
	}
	return @senses;
}

sub index_dict
{
	my ($self, $dict) = @_;
	my $iNewDict = $#{$self->{'index'}}+1;
	if (ref $dict eq ref $self)
	{
		foreach my $iDict(0..$#{$self->{'index'}})
		{
			foreach my $sOHW (keys %{$dict->{'index'}[$iDict]})
			{
				my $sHW = $self->norm_hw($sOHW);
				foreach my $sOPos (keys %{$dict->{'index'}[$iDict]{$sOHW}})
				{
					my $sPos = $self->norm_pos($sOPos);
					push (@{$self->{'index'}[$iNewDict]{$sHW}{$sPos}}, $dict->get_senses_for($sOHW, $sOPos));
				}
			}
		}
	}
	else
	{
		foreach my $sOHW (keys %{$dict->{'index'}})
		{
			my $sHW = $self->norm_hw($sOHW);
			foreach my $sOPos (keys %{$dict->{'index'}{$sOHW}})
			{
				my $sPos = $self->norm_pos($sOPos);
				push (@{$self->{'index'}[$iNewDict]{$sHW}{$sPos}}, $dict->get_senses_for($sOHW, $sOPos));
			}
		}
	}
}



1;


=pod

=head1 NAME

WordLists::Lookup

=head1 SYNOPSIS
	
	my $lookup = WordLists::Lookup->new({ dicts=>[$simple_dict, $technical_dict, $ten_volume_dict ]});
	$lookup->get_senses_for('aortic');
	# Nothing in $simple_dict, so fall back to $technical_dict or $ten_volume_dict.

=head1 DESCRIPTION	

A lookup is a way of accessing one or more L<WordList::WordList> or L<WordList::Dict> (or indeed L<WordList::Lookup>) objects and searching them 'fuzzily' - that is to say, you can access case insentitively, or ignoring spaces, etc. 

L<WordList::Lookup> objects are subclasses of L<WordList::WordList> and inherit all methods.

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut