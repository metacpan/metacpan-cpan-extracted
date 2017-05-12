#
# Web::DataService::IDocument
# 
# This is a role that provides access to dataservice documentation.  It is
# designed to be composed into the classes used for documenting dataservice
# nodes.


use strict;

package Web::DataService::IDocument;

use Moo::Role;


# document_node ( )
# 
# Return the documentation string for this node, if one was defined.  If an
# "extended_doc" string was also defined for this node, return it as well.

sub document_node {
    
    my ($request) = @_;
    
    my $ds = $request->ds;
    my $path = $request->node_path;
    my $extended = $ds->{extdoc_node}{$path};
    
    if ( ref $extended eq 'HASH' )
    {
	my $disp = $extended->{disp};
	
	if ( $disp eq 'replace' )
	{
	    return $extended->{doc_string};
	}
	
	my $doc_string = $ds->node_attr($path, 'doc_string') // '';
	
	$doc_string .= "\n\n" if $disp eq 'para' && $doc_string ne '';
	
	return $doc_string . $extended->{doc_string};
    }
    
    else
    {
	return $ds->node_attr($path, 'doc_string');
    }
}


# list_navtrail ( )
# 
# Return a list of navigation trail components for the current request, in POD
# format.  This is derived component-by-component from the request path.

sub list_navtrail {
    
    my ($request, $base_label) = @_;
    
    my $path = $request->node_path || '/';
    my $ds = $request->ds;
    
    $base_label ||= $ds->node_attr($path, 'title') || '';
    
    # If there are no path components, return just the base label.
    
    return $base_label if $path eq '/';
    
    # Otherwise, split the path into components and go through them one by one.
    
    my @trail = $ds->node_link('/', $base_label);
    my @path = split qr{/}, $path;
    my $node = "";
    my $count = $#path;
    
    foreach my $component (@path)
    {
	$node .= '/' if $node;
	$node .= $component;

	if ( $count-- == 0 )
	{
	    push @trail, $ds->node_attr($node, 'title') || $component;
	}
	
	else
	{
	    push @trail, $ds->node_link($node);
	}
    }
    
    return @trail;
}


# list_http_methods ( )
# 
# Return a list of the HTTP methods that are allowed for this request path.

sub list_http_methods {

    my ($request) = @_;
    
    my $methods = $request->{ds}->node_attr($request, 'allow_methods');
    return @Web::DataService::DEFAULT_METHODS unless ref $methods eq 'HASH';
    return grep { $methods->{$_} } @Web::DataService::HTTP_METHOD_LIST;
}


# document_http_methods ( )
# 
# Return a string documenting the HTTP methods that are allowed for this
# request path.

sub document_http_methods {
    
    my ($request) = @_;
    
    my $doc = join(', ', map { "C<$_>" } $request->list_http_methods);
    return $doc || '';
}


# list_subnodes
# 
# Return a list of sub-nodes of the current one.  This will include all
# sub-nodes with a value for the node attribute 'place', in order by the value
# of that attribute.

sub list_subnodes {
    
    my ($request) = @_;
    
    my $ds = $request->ds;
    my $path = $request->node_path;
    
    return $ds->list_subnodes($path);
}


# document_subnodes ( options )
# 
# Return a documentation string in Pod format listing the subnodes (if any)
# given for this node.  See &list_subnodes above.

sub document_nodelist {

    my ($request, $options) = @_;
    
    $options ||= {};
    
    my $ds = $request->ds;
    my $path = $options->{list} || $request->node_path;
    $options->{base} = $request->base_url;
    
    return $ds->document_nodelist($path, $options);
}


# document_usage 
# 
# Return a documentation string in Pod format describing the usage examples of
# the node corresponding to this request.

sub document_usage {

    my ($request, $options) = @_;
    
    my $ds = $request->ds;
    my $path = $request->node_path;
    
    return $ds->document_usage($path, $options);
}


# document_params ( )
# 
# Return a documentation string in POD format describing the parameters
# available for this request.

sub document_params {
    
    my ($request, $ruleset_name) = @_;
    
    my $ds = $request->{ds};
    my $validator = $ds->validator;
    
    $ruleset_name ||= $ds->determine_ruleset($request->node_path);
    
    # Generate documentation about the parameters, using the appropriate
    # method from the validator class (HTTP::Validate).  If no ruleset
    # is selected for this request, then state that no parameters are accepted.
    
    return $ruleset_name ? $validator->document_params($ruleset_name) : '';
}


# output_label ( )
# 
# Return the output label for the node corresponding to this request.

sub output_label {
    
    my ($request) = @_;
    
    return $request->{ds}->node_attr($request, 'output_label') || 'basic';
}


# optional_output ( )
# 
# Return the name of the optional output map, if any.

sub optional_output {
    
    my ($request) = @_;
    
    return $request->{ds}->node_attr($request, 'optional_output');
}


# document_response ( )
# 
# Return a documentation string in POD format describing the fields that can
# be included in the result.

sub document_response {
    
    my ($request, $options) = @_;
    
    my $ds = $request->{ds};
    
    return $ds->document_response($request->node_path, $options);
}


# document_summary ( )
# 
# Return a documentation string in POD format describing the fields that can
# be included in the summary block.  If no summary block was specified for
# this operation, return the empty string.

sub document_summary {

    my ($request, $options) = @_;
    
    my $ds = $request->{ds};
    
    return $ds->document_summary($request->node_path, $options);
}


# document_formats ( extended )
# 
# Return a string in POD format documenting the formats allowed for the path
# associated with this request.  If $extended is true, then include a text
# description of each format.

sub document_formats {

    my ($request, $options) = @_;
    
    $options ||= {};
    my ($path) = $options->{all} ? ('/') : ($options->{path} || $request->node_path);
    
    return $request->ds->document_formats($path, $options);
}


# defualt_format ( )
# 
# Return the name of the default format (if any) for this request's path.

sub default_format {
    
    $_[0]->ds->node_attr($_[0], 'default_format');
}


# document_vocabs ( extended )
# 
# Return a string in POD format documenting the vocabularies allowed for the
# path associated with this request.  If $extended is true, then include a
# text description of each vocabulary.

sub document_vocabs {
    
    my ($request, $options) = @_;
    
    $options = {} unless ref $options;
    my $path = $options->{all} ? '/' : $request->node_path;
    
    return $request->ds->document_vocabs($path, $options);
}


# pod_B, pod_I, pod_C
# 
# These functions are intended for use as filters.  They take a list of
# arguments and return a string consisting of the list items joined by commas
# and surrounded by the appropriate formatting code.

sub pod_B {
    return "B<" . join(', ', @_) . ">";
}


sub pod_C {
    return "C<" . join(', ', @_) . ">";
}


sub pod_I {
    return "I<" . join(', ', @_) . ">";
}



1;
