#
# Web::DataService::Format
# 
# This module provides a role that is used by 'Web::DataService'.  It implements
# routines for defining and documenting output formats.
# 
# Author: Michael McClennen

use strict;

package Web::DataService::Format;

use Carp 'croak';
use Data::Dumper;

use Moo::Role;


our (%FORMAT_DEF) = (name => 'ignore',
		     suffix => 'single',
		     title => 'single',
		     content_type => 'single',
		     disposition => 'single',
		     uses_header => 'single',
		     is_text => 'single',
		     encode_as_text => 'single',
		     default_vocab => 'single',
		     doc_node => 'single',
		     module => 'single',
		     package => 'single',
		     doc_string => 'single',
		     undocumented => 'single',
		     disabled => 'single');

our (%FORMAT_CT) = (json => 'application/json',
		    txt => 'text/plain',
		    tsv => 'text/tab-separated-values',
		    csv => 'text/csv',
		    xml => 'text/xml');

our (%FORMAT_CLASS) = (json => 'Web::DataService::Plugin::JSON',
		       txt => 'Web::DataService::Plugin::Text',
		       tsv => 'Web::DataService::Plugin::Text',
		       csv => 'Web::DataService::Plugin::Text',
		       xml => 'Web::DataService::Plugin::XML');


# define_format ( attrs... )
# 
# Define one or more formats for data service responses.

sub define_format {

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
	    
	    croak "define_format: the attributes must include 'name'" unless defined $name;
	    
	    # Make sure this format was not already defined by a previous call.
	    
	    croak "define_format: '$name' was already defined" if defined $ds->{format}{$name};
	    
	    # Create a new record to represent this format and check the attributes.
	    
	    my $record = bless { name => $name }, 'Web::DataService::Format';
	    
	    foreach my $k ( keys %$item )
	    {
		croak "define_format: invalid attribute '$k'" unless $FORMAT_DEF{$k};
		
		my $v = $item->{$k};
		
		if ( $k eq 'default_vocab' && defined $v && $v ne '' )
		{
		    croak "define_format: unknown vocabulary '$v'"
			unless ref $ds->{vocab}{$v};
		    
		    croak "define_format: cannot default to disabled vocabulary '$v'"
			if $ds->{vocab}{$v}{disabled} and not $item->{disabled};
		}
		
		$record->{$k} = $item->{$k};
	    }
	    
	    # Set defaults and check values.
	    
	    $record->{content_type} ||= $FORMAT_CT{$name};
	    $record->{uses_header} //= 1 if $name eq 'txt' || $name eq 'tsv' || $name eq 'csv';
	    $record->{is_text} //= 1 if $record->{content_type} =~ /(x(?:ht)?ml|text|json|javascript)/
		|| $record->{encode_as_text};
	    
	    croak "define_format: you must specify an HTTP content type for format '$name' using the attribute 'content_type'"
		unless $record->{content_type};
	    
	    $record->{package} //= $record->{module};
	    $record->{package} //= $FORMAT_CLASS{$name};
	    
	    croak "define_format: you must specify a package to implement format '$name' using the attribute 'module'"
		unless defined $record->{package};
	    
	    $record->{module} //= $record->{package};
	    
	    # Make sure that the module is loaded, unless the format is disabled.
	    
	    if ( $record->{module} && ! $record->{disabled} )
	    {
		my $filename = $record->{module};
		$filename =~ s{::}{/}g;
		$filename .= '.pm' unless $filename =~ /\.pm$/;
		
		require $filename;
	    }
	    
	    # Now store the record as a response format for this data service.
	    
	    $ds->{format}{$name} = $record;
	    push @{$ds->{format_list}}, $name unless $record->{disabled};
	    $last_node = $record;
	}
	
	# A scalar is taken to be a documentation string.
	
	elsif ( not ref $item )
	{
	    $ds->add_node_doc($last_node, $item);
	}
	
	else
	{
	    croak "define_format: the arguments to this routine must be hashrefs and strings";
	}
    }    
    
    croak "define_format: you must include at least one hashref of attributes"
	unless $last_node;
}


# list_formats ( )
# 
# Return the list of names of all the formats that have been defined for this
# data service.

sub list_formats {
    
    my ($ds) = @_;
    return @{$ds->{format_list}};
}


# valid_format ( )
# 
# Return a code reference (actually a reference to a closure) that can be used
# in a parameter rule to validate a format-selecting parameter.  All
# non-disabled formats are included.

sub format_validator {
    
    my ($self) = @_;
    
    # The ENUM_VALUE subroutine is defined by HTTP::Validate.pm.
    
    return ENUM_VALUE(@{$self->{format_list}});
}


# document_formats ( path, options )
# 
# Return a string containing POD documentation of the response formats that
# are allowed for the request path.  If the root path '/' is specified, then
# document all of the formats enabled for this data service regardless of
# whether they are actually allowed for that path.  But formats marked as
# undocumented are never shown.  If the option 'extended' is specified, then
# include the text description of each format.

sub document_formats {

    my ($ds, $path, $options) = @_;
    
    $options ||= {};
    $path ||= '/';
    
    # If no formats have been defined, return a note to that effect.
    
    return "MSG_FORMAT_NONE_DEFINED"
	unless ref $ds->{format_list} eq 'ARRAY';
    
    # Now figure out which formats to document.  If the path is '/', then
    # document all of them.  Otherwise, go thorugh the list of defined formats
    # in order, filtering out those which are not allowed for this path.  The
    # reason for doing it this way is so that the formats will always be
    # listed in the order defined, instead of the arbitrary hash order.
    
    my @formats;
    
    if ( $path eq '/' )
    {
	@formats = grep { ! $ds->{format}{$_}{undocumented} } @{$ds->{format_list}};
	return "MSG_FORMAT_NONE_DEFINED" unless @formats;
    }
    
    else
    {
	my $allowed = $ds->node_attr($path, 'allow_format');
	
	return "MSG_FORMAT_NONE_ALLOWED"
	    unless ref $allowed eq 'HASH';
	
	@formats = grep { $allowed->{$_} && ! $ds->{format}{$_}{undocumented} } @{$ds->{format_list}};
	return "MSG_FORMAT_NONE_ALLOWED" unless @formats;
    }
    
    # Go through the list of defined formats in order, 
    
    my @paths = grep { $ds->{format}{$_}{doc_node} } @formats;
    
    my $name_header = $ds->has_feature('format_suffix') ? 'Suffix' : 'Name';
    my $ext_header = $options->{extended} || ! @paths ? "| Description" : '';
    my $doc_header = @paths ? "| Documentation" : '';
    
    my $doc = "=for wds_table_header Format* | $name_header $doc_header $ext_header\n\n";
    $doc .= "=over 4\n\n";
    
 FORMAT:
    foreach my $name (@formats)
    {
	my $frec = $ds->{format}{$name};
	my $title = $frec->{title} || $frec->{name};
	my $doc_link = $ds->node_link($frec->{doc_node}) if $frec->{doc_node};
	my $name_or_suffix = $ds->has_feature('format_suffix') ? ".$frec->{name}" : $frec->{name};
	
	next FORMAT if $frec->{undocumented};
	
	$doc .= "=item $title | C<$name_or_suffix>";
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
