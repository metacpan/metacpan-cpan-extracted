package WordLists::Dict;
use strict;
use warnings;
use utf8;
use WordLists::Sense;
use base qw(WordLists::WordList);
use WordLists::Base;
our $VERSION = $WordLists::Base::VERSION;

use Scalar::Util;
our $AUTOLOAD;

sub new
{
	my ($class, $args) = @_;
	$args->{'name'} = 'DICT' unless defined $args->{'name'};
	return WordLists::WordList::new($class,$args);
}

sub add_sense
{
	my ($self, $sense) = @_;
	warn "Sense already belongs to another dictionary" if $sense->{'#dictparent'};
	$sense->set('dict', $self->{'name'});
	$sense->{'#dictparent'} = $self;
	Scalar::Util::weaken($sense->{'#dictparent'});
	my $success = $self->_add_sense_to_list($sense);
	$self->_index_sense($sense);
	return $success;
}
1;

=pod

=head1 NAME

WordLists::Dict

=head1 SYNOPSIS

	my $dict = WordLists::Dict->new({name=>'MyDictionary'});
	$dict->add_sense($sense); 
	# $sense->get('dict') now returns 'MyDictionary'
	my @senses = $dict->get_senses_for('head', 'verb');

=head1 DESCRIPTION	

A dictionary is a list of senses, rather like a wordlist, with the exception that adding a sense to a dictionary marks it as belonging to that dictionary.
This is useful when creating wordlists derived from several dictionaries, as you can then clearly see which belongs to which - if you remember to output dict, of course!

=head1 BUGS

Please use the Github issues tracker.

=head1 LICENSE

Copyright 2011-2012 © Cambridge University Press. This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
