package WordLists::WordList;
use strict;
use warnings;
use utf8;
use WordLists::Sense;
use WordLists::Common qw (@sDefaultAttList @sDefiningAttlist @sParsingParameters);
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;
our $AUTOLOAD;
our $DEFAULT_ENCODING = 'ascii';
our $NO_SENSE_IDENTITY = 'ascii';


sub new
{
	my ($class,  $args) = @_;
	my $self = {
		default_attlist => \@sDefaultAttList,
		defining_attlist => \@sDefiningAttlist,
	};
	
	bless ($self, $class);
	if ( ref $args eq 'HASH')
	{
		if (defined $args->{'parser'})
		{
			$self->parser($args->{'parser'});
		}
		if (defined $args->{'serialiser'})
		{
			$self->serialiser($args->{'serialiser'});
		}
		if (defined $args->{'name'})
		{
			$self->{'name'} = $args->{'name'};
		}
		if (defined $args->{'attlist'})
		{
			$self->{'attlist'} = $args->{'attlist'}; # todo: validate this
		}
		if (defined $args->{'from_string'})
		{
			$self->read_string($args->{'from_string'});
		}
		elsif (defined $args->{'from_file'})
		{
			$self->read_file($args->{'from_file'}, $args->{'encoding'});
		}	
	}
	return $self;
}

sub read_file # warning: this doesn't squash BOMs
{
	my ($self, $fn, $enc) = @_;
	my $args = {};
	if (defined $self->{'attlist'})
	{
		$args->{'attlist'} = $self->{'attlist'};
	}
	foreach (@{$self->parser->parse_file($fn, $enc,$args)})
	{
		$self->read_hash($_);
	}
}

sub read_hash
{
	my ($self, $hash, $args) = @_;
	my $sense = WordLists::Sense->new($hash);
	if (ref $sense eq 'WordLists::Sense')
	{
		$self->add_sense($sense);
	}
}
sub read_array
{
	my ($self, $array, $args) = @_;
	foreach my $hash (@{$array})
	{
		if (ref $hash eq ref {})
		{
			$self->read_hash($hash) ;
		}
		else
		{
			warn 'Expecting $wl->read_array([{}])'
		}
	}
	return $self;
}

sub read_string
{
	my ($self, $s, $args) = @_;
	{
		my $parsed = $self->parser->parse_string($s);
		$parsed = [$parsed] if (ref ($parsed) eq ref {});
		return $self->read_array($parsed, $args);
	}
}
sub to_string
{
	my ($self, $args) = @_;
	foreach(@sParsingParameters)
	{
		$args->{$_} = $self->{$_} unless defined $args->{$_};
	}
	my $senses = [map {$_->to_hash($args)} $self->get_all_senses];
	return $self->serialiser->to_string($senses, $args);
}

sub compare_senses
{
	my ($self, $sense_a, $sense_b, $args) = @_;
	my $cmp = [
		{'name' => 'hw', 'c' => sub{lc $_[0] cmp lc $_[1] }}
	];
	if (defined($args->{'sense_compare'}) and ref ($args->{'sense_compare'}) eq ref [])
	{
		$cmp = $args->{'sense_compare'};
	}
	foreach (@{$cmp})
	{
		my $result = 0;
		if (defined $_->{'name'})
		{
			$result = &{$_->{'c'}}(
				$sense_a->get($_->{'name'}),
				$sense_b->get($_->{'name'})
			);
		}
		else
		{
			$result = &{$_->{'c'}}(
				$sense_a,
				$sense_b
			);
		}
		return $result unless $result == 0;
	}
	return 0;
}
sub sort
{
	my ($self, $args) = @_;
	$self->{'senses'} = [sort {$self->compare_senses($a, $b, $args)} @{$self->{'senses'}}];
	return 1;
}

sub get_senses_for
{
	my ($self, $sHW, $sPos) = @_;
	my @senses;
	if (defined $sPos and ($sPos or $self->{'significant_empty_pos'}))
	{
		@senses = @{$self->{'index'}{$sHW}{$sPos}} if defined $self->{'index'}{$sHW}{$sPos};
	}
	elsif (defined $sHW)
	{
		foreach my $sPos (keys %{$self->{'index'}{$sHW}})
		{
			push @senses, @{$self->{'index'}{$sHW}{$sPos}};
		}
	}
	return @senses;
}
sub get_all_senses
{
	my ($self) = @_;
	return () unless defined $self->{'senses'};
	return @{$self->{'senses'}};
}
sub get_current_attlist
{
	my ($self) = @_;
	if ($self->{'attlist'})
	{
		return @{$self->{'attlist'}};
	}
	return @{$self->{'default_attlist'}};
}
sub get_default_attlist
{
	my ($self) = @_;
	return @{$self->{'default_attlist'}}
}
sub add_sense
{
	my ($self, $sense) = @_;
	my $success = $self->_add_sense_to_list($sense);
	$self->_index_sense($sense);
	return $success;
}
sub _add_sense_to_list
{
	my ($self, $sense) = @_;
	return push (@{$self->{'senses'}}, $sense);
}
sub _index_sense
{
	my ($self, $sense) = @_;
	my $sHW = $sense->get_hw;
	my $sPos = $sense->get_pos;
	$sHW ||='';
	$sPos ||='';
	return push (@{$self->{'index'}{$sHW}{$sPos}}, $sense);
}

sub _rebuild_index
{
	my ($self) = @_;
	my $index = $self->{'index'};
	$index = ();
	foreach my $sense (@{$self->{'senses'}})
	{
		push (@{$index->{$sense->get_hw}{$sense->get_pos}}, $sense);
	}
}



sub parser
{
	my ($self, $parser) = @_;
	if (defined $parser)
	{
		$self->{'#parser'} = $parser;
	}
	if (defined $self->{'#parser'})
	{
		return $self->{'#parser'}
	}
	else
	{
		use WordLists::Parse::Simple;
		$self->{'#parser'} = WordLists::Parse::Simple->new();
	}
}
sub serialiser
{
	my ($self, $serialiser) = @_;
	if (defined $serialiser)
	{
		$self->{'#serialiser'} = $serialiser;
	}
	if (defined $self->{'#serialiser'})
	{
		return $self->{'#serialiser'}
	}
	else
	{
		use WordLists::Serialise::Simple;
		return $self->{'#serialiser'} = WordLists::Serialise::Simple->new();
	}
}

1;

=pod

=head1 NAME

WordLists::WordList

=head1 SYNOPSIS

	my $wl = WordLists::WordList->new({from_file=>'unit1.txt'});
	my @senses = $wl->get_senses_for('book', 'verb');
	$wl->add_sense($new_sense);
	print OUT $wl->to_string;

=head1 DESCRIPTION

WordLists::WordList is a base class for a group of L<WordLists::Sense> objects.

=head3 new

The constructor creates an empty wordlist, and will populate the wordlist if you pass it parameters such as C<from_string> and C<from_file> (in which case, you can also specify C<encoding>). These parameters should be passed in a hash ref (as per the example in the synopsis). You can populate the wordlist later, of course.

=head3 parser

This is an accessor for the parser, and returns the parser and/or sets the parser if given one. The parser defaults to L<WordLists::Parse::Simple>, and the parser is created the first time it is requested (not when the L<WordLists::WordList> object is created, unless C<from_file> or C<from_string> is used).

=head3 serialiser

This is an accessor for the serialiser, and returns the serialiser and/or sets the serialiser if given one. The serialiser defaults to L<WordLists::Serialise::Simple>, and the serialiser is created the first time it is requested (not when the L<WordLists::WordList> object is created).

=head3 get_senses_for

This returns senses which match the parameters specified (hw, pos).

=head3 get_all_senses

This returns all senses; by default, it will return them in the order in which they were entered, but senses can be reordered using the C<sort> method.

=head1 TODO

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
