#
# Web::DataService::Vocabulary.pm
# 
# This module provides a role that is used by 'Web::DataService'.  It implements
# routines for defining and documenting vocabularies.
# 
# Author: Michael McClennen

use strict;

package Web::DataService::Vocabulary;

use Carp 'croak';

use Moo::Role;

our (%VOCAB_DEF) = (name => 'ignore',
		    title => 'single',
		    doc_node => 'single',
		    use_field_names => 'single',
		    undocumented => 'single',
		    disabled => 'single');


# define_vocab ( attrs... )
# 
# Define one or more vocabularies for data service responses.  These
# vocabularies provide field names for the responses.

sub define_vocab {

    my $ds = shift;
    
    my ($last_node);
    
    # Now we go through the rest of the arguments.  Hashrefs define new
    # vocabularies, while strings add to the documentation of the vocabulary
    # whose definition they follow.
    
    foreach my $item (@_)
    {
	# A hashref defines a new vocabulary.
	
	if ( ref $item eq 'HASH' )
	{
	    # Make sure the attributes include 'name'.
	    
	    my $name = $item->{name}; 
	    
	    croak "define_vocab: you must include the attribute 'name'" unless $name;
	    
	    # Make sure this vocabulary was not already defined by a previous call,
	    # and set the attributes as specified.
	    
	    croak "define_vocab: '$name' was already defined" if defined $ds->{vocab}{$name}
		and not $ds->{vocab}{$name}{_default};
	    
	    # Create a new record to represent this vocabulary.
	    
	    my $record = bless { name => $name }, 'Web::DataService::Vocab';
	    
	    # If this entry is for the 'null' vocabulary, then use the
	    # existing record.  If this record is to be disabled,
	    # remove it from the vocabulary list.
	    
	    if ( $name eq 'null' )
	    {
		$record = $ds->{vocab}{null};
		shift @{$ds->{vocab_list}} if $item->{disabled};
	    }
	    
	    # Now set the attributes for this vocabulary.
	    
	    foreach my $k ( keys %$item )
	    {
		croak "define_vocab: invalid attribute '$k'" unless $VOCAB_DEF{$k};
		
		$record->{$k} = $item->{$k};
	    }
	    
	    # Now install the new vocabulary.  But don't add it to the list if
	    # the 'disabled' attribute is set.
	    
	    $ds->{vocab}{$name} = $record;
	    push @{$ds->{vocab_list}}, $name unless $record->{disabled};
	    $last_node = $record;
	}
	
	# A scalar is taken to be a documentation string.
	
	elsif ( not ref $item )
	{
	    $ds->add_node_doc($last_node, $item);
	}
	
	else
	{
	    croak "define_vocab: arguments must be hashrefs and strings";
	}
    }
    
    croak "define_vocab: the arguments must include a hashref of attributes"
	unless $last_node;
}


# list_vocabs ( )
# 
# Return the list of names of all the vocabularies that have been defined for
# this data service.

sub list_vocabs {

    my ($ds) = @_;
    return @{$ds->{vocab_list}};
}


# valid_vocab ( )
# 
# Return a code reference (actually a reference to a closure) that can be used
# in a parameter rule to validate a vocaubulary-selecting parameter.  All
# non-disabled vocabularies are included.

sub valid_vocab {
    
    my ($ds) = @_;
    
    # The ENUM_VALUE subroutine is defined by HTTP::Validate.pm.
    
    return HTTP::Validate::ENUM_VALUE(@{$ds->{vocab_list}});
}


# document_vocabs ( path, options )
# 
# Return a string containing POD documentation of the response vocabularies
# that are allowed for the specified path.  If the option 'all' is true, then
# document all of the vocabularies enabled for this data service regardless of
# whether they are actually allowed for that path.
# 
# If the option 'extended' is true, then include the text description of each
# vocabulary.

sub document_vocabs {

    my ($ds, $path, $options) = @_;
    
    $options ||= {};
    $path ||= '/';
    
    # Go through the list of defined vocabularies in order, filtering out
    # those which are not allowed for this path.  The reason for doing it this
    # way is so that the vocabularies will always be listed in the order
    # defined, instead of the arbitrary hash order.
    
    my @vocabs;
    
    if ( $path eq '/' )
    {
	@vocabs = grep { ! $ds->{vocab}{$_}{undocumented} } @{$ds->{vocab_list}};
    }
    
    else
    {
	my $allowed = $ds->node_attr($path, 'allow_vocab');
	
	return '' unless ref $allowed eq 'HASH';
	
	@vocabs = grep { $allowed->{$_} && ! $ds->{vocab}{$_}{undocumented} } @{$ds->{vocab_list}};
	return '' unless @vocabs;    
    }
    
    # Figure out the default formats for each vocabulary.
    
    my %default_for;
    
    foreach my $format ( @{$ds->{format_list}} )
    {
	my $default_vocab = $ds->{format}{$format}{default_vocab} // $ds->{vocab_list}[0];
	push @{$default_for{$default_vocab}}, "C<$format>" if $default_vocab;
    }
    
    # Go through the list of defined vocabularies in order, 
    
    my @paths = grep { $ds->{vocab}{$_}{doc_node} } @vocabs;
    
    my $ext_header = $options->{extended} || ! @paths ? " | Description" : '';
    my $doc_header = @paths ? " | Documentation" : '';
    
    my $doc = "=for wds_table_header Vocabulary* | Name | Default for $doc_header $ext_header\n\n";
    $doc .= "=over\n\n";
    
    if ( $options->{valid} )
    {
	$doc = "=for wds_table_no_header Value* | Description\n\n";
	$doc .= "=over\n\n";
    }
    
 VOCABULARY:
    foreach my $name (@vocabs)
    {
	my $frec = $ds->{vocab}{$name};
	my $title = $frec->{title} || $frec->{name};
	my $def_list = $default_for{$name} ? join(', ', @{$default_for{$name}}) : '';
	my $doc_link = $ds->node_link($frec->{doc_node}) if $frec->{doc_node};
	
	next VOCABULARY if $frec->{undocumented};
	
	if ( $options->{valid} )
	{
	    $doc .= "=item C<$frec->{name}>\n\n";
	    $doc .= "$frec->{doc_string}\n\n" if $frec->{doc_string};
	    next;
	}
	
	$doc .= "=item $title | C<$frec->{name}> | $def_list";
	$doc .= " | $doc_link" if $doc_link && @paths && $options->{extended};
	$doc .= "\n\n";
	
	if ( $options->{extended} || ! @paths )
	{
	    $doc .= "$frec->{doc_string}\n\n" if $frec->{doc_string};
	}
	
	elsif ( $doc_link )
	{
	    $doc .= "$doc_link\n\n";
	}
    }
    
    $doc .= "=back";
    
    return $doc;
}


1;
