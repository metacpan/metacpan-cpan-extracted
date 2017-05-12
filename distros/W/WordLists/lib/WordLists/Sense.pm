package WordLists::Sense;
use strict;
use warnings;
use utf8;
our $AUTOLOAD;
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;

=head1 NAME

WordLists::Sense - Class for senses in wordlists, dictionaries, etc.

=head1 SYNOPSIS

  use WordLists::Sense;
  my $sense = WordLists::Sense->new();
  $sense->set('hw', 'head');
  $sense->set('pos', 'noun');
  $sense->set_pos('verb'); # alternative
  $sense->has('pos'); # returns 1
  $sense->get('pos'); # returns 'verb'
  $sense->to_string; # returns "head\tverb" - however it is better to do this from within a wordlist
  my $another_sense = WordLists::Sense->new({hw=>'head', pos=>'verb'});

This class is a very simple class which is little more than a blessed hash with accessors C<set>, C<get>, and C<has>.

The following attributes are 'special' - treated no differently by this module but by others:

=over

=item *
C<hw> - ('headword') - all searches will be keyed to this

=item *
C<pos> - ('part of speech') - this is a discriminator for finer control

=item *
C<dict> - ('dictionary') - this is set by a L<WordLists::Dict> object when the sense is added to that object to assert provenance

=back

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

sub new
{
	my ($class,  $args) = @_;
	my $self = $args;
	$self ||={};
	bless ($self, $class);
	return $self;
}

sub get
{
	my ($self,  $attr) = @_;
	return $self->{$attr};
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
		$self->{'#serialiser'} = WordLists::Serialise::Simple->new();
	}
}


sub set
{
	my ($self,  $attr, $value) = @_;
	return $self->{$attr} = $value;
}
sub has
{
	my ($self,  $attr) = @_;
	return defined $self->{$attr};
}
sub read_hash
{
	my ($self, $hash, $args) = @_;
	foreach (keys %{$hash})
	{
		$self->set($_, $hash->{$_});
	}
	return $self;
}
sub to_hash
{
	my ($self, $args) = @_;
	my $hash = {};
	unless (defined $args->{'fields'})
	{
		$args->{'fields'} = [];
		push (@{$args->{'fields'}} , $_) foreach keys %{ $self }  ;
	}
	$hash->{$_} = $self->get($_) foreach @{$args->{'fields'}};
	return $hash;
}
sub to_string # should we ditch this?
{
	my ($self, $args) = @_;
	my $opts = {
		field_prefix => "",
		field_suffix => "",
		sense_prefix => "",
		sense_suffix => "",
		separator    => "\t",
		fields       => [qw(hw pos def eg)],
		field_escape => sub { return defined $_[0] ? $_[0] : ''; },
		defined $args ? %$args : (),
	};

	my $s = 
		$opts->{'sense_prefix'} .
		join ($opts->{'separator'}, map {
			$opts->{'field_prefix'} .
			&{$opts->{'field_escape'}}($self->get($_), $_) .
			$opts->{'field_suffix'}			
		} @{$opts->{'fields'}})
		. $opts->{'sense_suffix'}
		;
	return $s;
}

sub AUTOLOAD
{
	my $self = shift;
	return if ($AUTOLOAD =~ /DESTROY/);
	if ( ($AUTOLOAD =~ /.*::set_(\w+)/) and (@_) )
	{
        return $self->{$1} = shift;
    }
	elsif ($AUTOLOAD =~ /.*::get_(\w+)/) 
	{
        return $self->{$1};
    }
	elsif ($AUTOLOAD =~ /.*::has_(\w+)/) 
	{
        return defined $self->{$1};
    }
}


1;
