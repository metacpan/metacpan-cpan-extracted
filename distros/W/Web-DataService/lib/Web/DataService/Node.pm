#
# Web::DataService::Node
# 
# This module provides a role that is used by 'Web::DataService'.  It implements
# routines for defining and querying data service nodes.
# 
# Author: Michael McClennen

use strict;

package Web::DataService::Node;

use Carp 'croak';
use Scalar::Util 'reftype';

use Moo::Role;


our (%NODE_DEF) = ( path => 'ignore',
		    disabled => 'single',
		    undocumented => 'single',
		    place => 'single',
		    list => 'single',
		    title => 'single',
		    usage => 'single',
		    collapse_tree => 'single',
		    file_dir => 'single',
		    file_path => 'single',
		    role => 'single',
		    method => 'single',
		    arg => 'single',
		    node_tag => 'set',
		    node_data => 'single',
		    ruleset => 'single',
		    output => 'list',
		    output_label => 'single',
		    optional_output => 'single',
		    summary => 'single',
		    public_access => 'single',
		    default_format => 'single',
		    default_limit => 'single',
		    default_header => 'single',
		    default_datainfo => 'single',
		    default_count => 'single',
		    default_linebreak => 'single',
		    default_save_filename => 'single',
		    stream_theshold => 'single',
		    init_operation_hook => 'hook',
		    post_params_hook => 'hook',
		    post_configure_hook => 'hook',
		    post_process_hook => 'hook',
		    output_record_hook => 'hook',
		    use_cache => 'single',
		    allow_method => 'set',
		    allow_format => 'set',
		    allow_vocab => 'set',
		    doc_string => 'single',
		    doc_template => 'single',
		    doc_default_template => 'single',
		    doc_default_op_template => 'single',
		    doc_defs => 'single',
		    doc_header => 'single',
		    doc_footer => 'single',
		  );


our (%NODE_NONHERITABLE) = ( title => 1,
			     doc_string => 1,
			     doc_template => 1,
			     place => 1,
			     usage => 1,
			   );

our (%NODE_ATTR_DEFAULT) = ( default_header => 1 );

our (%EXTENDED_DEF) = ( path => 1,
			type => 1,
			name => 1,
			disp => 1,
		      );

# define_node ( attrs... )
# 
# Set up a "path" entry, representing a complete or partial URL path.  This
# path should have a documentation page, but if one is not defined a template
# page will be used along with any documentation strings given in this call.
# Any path which represents an operation must be given an 'op' attribute.
# 
# An error will be signalled unless the "parent" path is already defined.  In
# other words, you cannot define 'a/b/c' unless 'a/b' is defined first.

sub define_node {
    
    my $ds = shift;
    
    my ($package, $filename, $line) = caller;
    
    my ($last_node);
    
    # Now we go through the rest of the arguments.  Hashrefs define new
    # nodes, while strings add to the documentation of the node
    # whose definition they follow.
    
    foreach my $item (@_)
    {
	# A hashref defines a new directory.
	
	if ( ref $item eq 'HASH' )
	{
	    croak "define_node: each definition must include a non-empty value for 'path'\n"
		unless defined $item->{path} && $item->{path} ne '';
	    
	    croak "define_node: invalid path '$item->{path}'\n" if $item->{path} ne '/' && 
		$item->{path} =~ qr{ ^ / | / $ | // | [?#] }xs;
	    
	    $last_node = $ds->_create_path_node($item, $filename, $line);
	}
	
	elsif ( not ref $item )
	{
	    $ds->add_node_doc($last_node, $item);
	}
	
	else
	{
	    croak "define_node: the arguments must be a list of hashrefs and strings\n";
	}
    }
    
    croak "define_node: arguments must include at least one hashref of attributes\n"
	unless $last_node;
}



# _create_path_node ( attrs, filename, line )
# 
# Create a new node representing the specified path.  Attributes are
# inherited, as follows: 'a/b/c' inherits from 'a/b', which inherits from 'a',
# which inherits from '/'.  If 'a/b' does not exist, then 'a/b/c' inherits
# directly from 'a'.

sub _create_path_node {

    my ($ds, $new_attrs, $filename, $line) = @_;
    
    my $path = $new_attrs->{path};
    
    # Make sure this path was not already defined by a previous call.
    
    if ( defined $ds->{path_defs}{$path} )
    {
	my $filename = $ds->{path_defs}{$path}{filename};
	my $line = $ds->{path_defs}{$path}{line};
	croak "define_node: '$path' was already defined at line $line of $filename\n";
    }
    
    else
    {
	$ds->{path_defs}{$path} = { filename => $filename, line => $line };
    }
    
    # Create a new node to hold the path attributes.
    
    my $node_attrs = { disabled => 0 };
    
    # Then apply the newly specified attributes, checking any list or set
    # values.
    
 KEY:
    foreach my $key ( keys %$new_attrs )
    {
	croak "define_node '$path': unknown attribute '$key'\n"
	    unless $NODE_DEF{$key};
	
	my $value = $new_attrs->{$key};
	
	# If the value is undefined or the empty string, store it and go on to
	# the next.  This means that the value should be considered unset.
	
	if ( ! defined $value || $value eq '' )
	{
	    $node_attrs->{$key} = $value;
	}
	
	# If the attribute takes a single value, then set the value as
	# specified.
	
	elsif ( $NODE_DEF{$key} eq 'single' )
	{
	    $node_attrs->{$key} = $value;
	}
	
	# If it takes a hook value, then the value can be either a list or a
	# singleton.  In either case, each value must be either a code ref or
	# a string.
	
	elsif ( $NODE_DEF{$key} eq 'hook' )
	{
	    if ( ref $value eq 'ARRAY' )
	    {
		foreach my $v ( @$value )
		{
		    croak "define_node '$path': $key has invalid value '$v', must be a code ref or string\n"
			unless ref $v eq 'CODE' || ! ref $v;
		}
	    }
	    
	    else
	    {
		croak "define_node '$path': $key has invalid value '$value', must be a code ref or string\n"
		    unless ref $value eq 'CODE' || ! ref $value;
		
		$value = [ $value ];
	    }
	    
	    $node_attrs->{$key} = $value;
	    $ds->{hook_enabled}{$key} = 1;
	}
	
	# If the attribute takes a set value, then check that it is
	# either a single value or a comma-separated list.  If any of the
	# values begin with + or -, then all must.
	
	elsif ( $NODE_DEF{$key} eq 'set' )
	{
	    unless ( $value =~ qr{ ^ (?> [\w.:][\w.:-]* | \s*,\s* )* $ }xs ||
		     $value =~ qr{ ^ (?> [+-][\w.:][\w.:-]* | \s*,\s* )* $ }xs )
	    {
		croak "define_node '$path': $key has invalid value '$value'\n";
	    }
	    
	    $node_attrs->{$key} = $value;
	    $ds->{path_compose}{$path}{$key} = 1 if $value =~ qr{ ^ (?> \s*,\s* )* [+-] }xs;
	}
	
	# If the attribute takes a list value, then check that it is either a
	# single value or a comma-separated list.
	
	elsif ( $NODE_DEF{$key} eq 'list' )
	{
	    unless ( $value =~ qr{ ^ (?> [\w.:-]+ | \s*,\s* )+ $ }xs )
	    {
		croak "define_node '$path': $key has invalid value '$value'\n";
	    }
	    
	    $node_attrs->{$key} = $value;
	}
	
	# Otherwise this attribute is ignored
	
	else
	{
	}
    }
    
    # Install the node.
    
    $ds->{node_attrs}{$path} = $node_attrs;
    
    my $place = $node_attrs->{place};
    
    if ( defined $place )
    {
	my $list = $node_attrs->{list} // $ds->path_parent($path);
	
	no warnings;
	if ( $place > 0 && defined $list && $list ne '' )
	{
	    push @{$ds->{node_list}{$list}{$place}}, { path => $path };
	}
	
	elsif ( $place ne '0' )
	{
	    croak "define_node '$path': invalid value for 'place' - must be a number\n";
	}
    }
    
    # Now check the attributes to make sure they are consistent:
    
    $ds->_check_path_node($path);
    
    # If one of the attributes is 'role', create a new request execution class
    # for this role unless we are in "one request" mode.
    
    my $role = $ds->node_attr($path, 'role');
    
    if ( $role and not $Web::DataService::ONE_REQUEST )
    {
	$ds->execution_class($role);
	$ds->documentation_class($role);
    }
    
    # Now return the new node.
    
    return $node_attrs;
}


sub _check_path_node {
    
    my ($ds, $path) = @_;
    
    # Throw an error if 'role' doesn't specify an existing module.
    
    my $role = $ds->node_attr($path, 'role');
    
    if ( $role )
    {
	no strict 'refs';
	
	croak "define_node '$path': the value of 'role' should be a package name, not a file name\n"
	    if $role =~ qr { [.] pm $ }xs;
	
	croak "define_node '$path': you must load the module '$role' before using it as the value of 'role'\n"
	    unless %{ "${role}::" };
    }
    
    # Throw an error if 'method' doesn't specify an existing method
    # implemented by this role.
    
    my $method = $ds->node_attr($path, 'method');
    
    if ( $method )
    {
	croak "define_node '$path': method '$method' is not valid unless you also specify its package using 'role'\n"
	    unless defined $role;
	
	croak "define_node '$path': '$method' must be a method implemented by '$role'\n"
	    unless $role->can($method);
    }
    
    # Throw an error if more than one of 'file_path', 'file_dir', 'method' are
    # set.
    
    my $attr_count = 0;
    
    $attr_count++ if $method;
    $attr_count++ if $ds->node_attr($path, 'file_dir');
    $attr_count++ if $ds->node_attr($path, 'file_path');
    
    if ( $method && $attr_count > 1 )
    {
	croak "define_node '$path': you may only specify one of 'method', 'file_dir', 'file_path'\n";
    }
    
    elsif ( $attr_count > 1 )
    {
	croak "define_node '$path': you may only specify one of 'file_dir' and 'file_path'\n";
    }
    
    # Throw an error if any of the specified formats fails to match an
    # existing format.  If any of the formats has a default vocabulary, add it
    # to the vocabulary list.
    
    my $allow_format = $ds->node_attr($path, 'allow_format');
    
    if ( ref $allow_format && reftype $allow_format eq 'HASH' )
    {
	foreach my $f ( keys %$allow_format )
	{
	    croak "define_node '$path': invalid value '$f' for format, no such format has been defined for this data service\n"
		unless ref $ds->{format}{$f};
	    
	    #my $dv = $ds->{format}{$f}{default_vocab};
	    #$node_attrs->{allow_vocab}{$dv} = 1 if $dv;
	}
    }
    
    # Throw an error if any of the specified vocabularies fails to match an
    # existing vocabulary.
    
    my $allow_vocab = $ds->node_attr($path, 'allow_vocab');
    
    if ( ref $allow_vocab && reftype $allow_vocab eq 'HASH' )
    {
	foreach my $v ( keys %$allow_vocab )
	{
	    croak "define_node '$path': invalid value '$v' for vocab, no such vocabulary has been defined for this data service\n"
		unless ref $ds->{vocab}{$v};
	}
    }
    
    # Throw an error if 'place' is not greater than zero.
    
    my $place = $ds->node_attr($path, 'place');
    
    no warnings;
    
    if ( defined $place && $place !~ qr{^[0-9]+$} )
    {
	croak "define_node '$path': the value of 'place' must be an integer";
    }
    
    my $a = 1;	# we can stop here when debugging;
}


our (%LIST_DEF) = ( path => 'single',
		    place => 'single',
		    list => 'single',
		    title => 'single',
		    usage => 'single',
		    doc_string => 'single' );

# list_node ( attrs... )
# 
# Add an entry to a node list.

sub list_node {

    my $ds = shift;
    
    my ($last_node);
    
    # Now we go through the rest of the arguments.  Hashrefs define new
    # list entries, while strings add to the documentation of the entry
    # whose definition they follow.
    
    foreach my $item (@_)
    {
	# A hashref defines a new directory.
	
	if ( ref $item eq 'HASH' )
	{
	    croak "list_node: each definition must include a non-empty value for 'path'\n"
		unless defined $item->{path} && $item->{path} ne '';
	    
	    croak "list_node: invalid path '$item->{path}'\n" if $item->{path} ne '/' && 
		$item->{path} =~ qr{ ^ / | / $ | // | [?#] }xs;
	    
	    $last_node = $ds->_create_list_entry($item);
	}
	
	elsif ( not ref $item )
	{
	    $ds->add_node_doc($last_node, $item);
	}
	
	else
	{
	    croak "list_node: the arguments must be a list of hashrefs and strings\n";
	}
    }
    
    croak "list_node: arguments must include at least one hashref of attributes\n"
	unless $last_node;
}


sub _create_list_entry {

    my ($ds, $item) = @_;
    
    # Start by checking the attributes.
    
    my $path = $item->{path};
    
 KEY:
    foreach my $key ( keys %$item )
    {
	croak "list_node '$path': unknown attribute '$key'\n"
	    unless $NODE_DEF{$key};
    }
    
    my $place = $item->{place};
    my $list = $item->{list};
    
    croak "list_node '$path': you must specify a numeric value for 'place'\n"
	unless defined $place && $place =~ qr{^[0-9]+$};
    
    croak "list_node '$path': you must specify a non-empty value for 'list'\n"
	unless defined $list && $list ne '';
    
    # Then install the item.
    
    push @{$ds->{node_list}{$list}{$place}}, $item if $place;
    
    return $item;
}


# extended_doc ( attrs ... )
# 
# Add extended documentation to one or more nodes.  The documentation strings
# defined by this call will be used to extend the documentation provided in
# the original node definitions.  By default, this extended documentation will
# be appended to the documentation string (if any) specified in the calls to
# 'define_node', for display at the top of the documentation page for each
# node.  The original documentation strings will be used to document lists of
# nodes.

sub extended_doc {
    
    my $ds = shift;
    
    my ($last_node);
    
    # Now we go through the rest of the arguments.  Hashrefs select or other
    # elements to be documented, while strings add to the documentation of the
    # selected element.
    
    foreach my $item (@_)
    {
	# A hashref selects a node to be documented.
	
	if ( ref $item eq 'HASH' )
	{
	    croak "extended_doc: each definition must include a non-empty value for either 'path' or 'type'\n"
		unless (defined $item->{path} && $item->{path} ne '' ||
			defined $item->{type} && $item->{type} ne '');
	    
	    croak "define_node: invalid path '$item->{path}'\n" if $item->{path} ne '/' && 
		$item->{path} =~ qr{ ^ / | / $ | // | [?#] }xs;
	    
	    $last_node = $ds->_select_extended_doc($item);
	}
	
	elsif ( not ref $item )
	{
	    $ds->_add_extended_doc($last_node, $item);
	}
	
	else
	{
	    croak "extended_doc: the arguments must be a list of hashrefs and strings\n";
	}
    }
    
    croak "extended_doc: arguments must include at least one hashref of attributes\n"
	unless $last_node;
}


# _select_extended_doc ( attrs )
# 
# Return a reference to the extended documentation record corresponding to the
# specified attributes.  Create the record if it does not already exist.

sub _select_extended_doc {
    
    my ($ds, $item) = @_;
    
    my $disp = $item->{disp} || '';
    my $type = $item->{type} || 'node';
    my $path = $item->{path};
    my $name = $path || $item->{name};

    croak "extended_doc: you must specify either 'name' or 'path' in each set of attributes\n"
	unless $name;
    
 KEY:
    foreach my $key ( keys %$item )
    {
	croak "extended_doc '$name': unknown attribute '$key'\n"
	    unless $EXTENDED_DEF{$key};
    }
    
    croak "extended_doc '$name': value of disp must be either 'replace', 'add' or 'para'\n"
	unless $disp eq '' || $disp eq 'replace' || $disp eq 'add' || $disp eq 'para';
    
    if ( $path )
    {
	croak "extended_doc '$path': you may not specify both 'path' and 'name'\n"
	    if $item->{name};
	
	croak "extended_doc '$path': type must be 'node' if you also specify 'path'\n"
	    if $type ne 'node';
	
	croak "extended_node '$path': no such node has been defined\n"
	    unless ref $ds->{node_attrs}{$path} eq 'HASH';
	
	$ds->{extdoc_node}{$path} ||= { path => $path, disp => 'para', type => 'node' };
	$ds->{extdoc_node}{$path}{disp} = $disp if $disp;
	return $ds->{extdoc_node}{$path};
    }
    
    elsif ( $type eq 'format' )
    {
	croak "extended_doc: you must specify either a path or a name for every record\n"
	    unless $name;
	
	croak "extended_doc '$name': no such format has been defined\n"
	    unless ref $ds->{format}{$name} eq 'Web::DataService::Format';
	
	$ds->{extdoc_format}{$name} ||= { name => $name, disp => 'para', type => 'format' };
	$ds->{extdoc_format}{$name}{disp} = $disp if $disp;
	return $ds->{extdoc_format}{$name};
    }
    
    elsif ( $type eq 'vocab' )
    {
	croak "extended_doc: you must specify either a path or a name for every record\n"
	    unless $name;
	
	croak "extended_doc '$name': no such vocabulary has been defined\n"
	    unless ref $ds->{format}{$name} eq 'Web::DataService::Vocab';
	
	$ds->{extdoc_vocab}{$name} ||= { name => $name, disp => $disp, type => 'vocab' };
	$ds->{extdoc_vocab}{$name}{disp} = $disp if $disp;
	return $ds->{extdoc_vocab}{$name};
    }
    
    else
    {
	croak "extended_doc '$name': you must specify an element type, i.e. 'vocab' or 'format'\n"
	    unless $type;
	
	croak "extended_doc '$type': you must specify a node path\n"
	    if $type eq 'node';
	
	croak "extended_doc '$name': invalid type '$type', must be either 'node', 'format' or 'vocab'\n"
	    unless $type eq 'node' || $type eq 'format' || $type eq 'vocab';
	
	croak "extended_doc '$name': invalid attributes";
    }
}


sub _add_extended_doc {
    
    my ($ds, $item, $doc) = @_;
    
    return unless defined $doc;
    
    my $name = $item->{path} || $item->{name};
    
    croak "extended_doc '$name': only strings may be added to documentation: $doc is not valid"
	if ref $doc;
    
    # If the string starts with either '>' or '>>', add an extra blank line so
    # that it becomes a new paragraph.  We ignore an initial '!'.  If you wish
    # to mark a node as undocumented, do so in the 'define_node' call.
    
    $doc =~ s{^>>?}{\n}xs;
    $doc =~ s{^[!]}{}xs;
    
    # Now add the documentation string.
    
    $item->{doc_string} = '' unless defined $item->{doc_string};
    $item->{doc_string} .= "\n" if $item->{doc_string} ne '';
    $item->{doc_string} .= $doc;
}


# node_defined ( path )
# 
# Return true if the specified path has been defined, false otherwise.

sub node_defined {

    my ($ds, $path) = @_;
    
    return unless defined $path;
    $path = '/' if $path eq '';
    
    return $ds->{node_attrs}{$path} && ! $ds->{node_attrs}{$path}{disabled};
}


# node_attr ( path, key )
# 
# Return the specified attribute for the given path.  These are computed
# lazily; if the specified attribute is already in the attribute cache, then
# return it.  Otherwise, we must look it up.

sub node_attr {
    
    my ($ds, $path, $key) = @_;
    
    # If we are given an object as the value of $path, pull out its
    # 'node_path' attribute, or else default to the root path '/'.
    
    if ( ref $path && reftype $path eq 'HASH' )
    {
	$path = $path->{node_path} || '/';
    }
    
    # If the specified attribute is in the attribute cache for this path, just
    # return it.  Even if the value is undefined. We need to turn off warnings
    # for this block, because either of $path or $key may be undefined.  The
    # behavior is correct in any case, we just don't want the warning.
    
    {
	no warnings;
	if ( exists $ds->{attr_cache}{$path}{$key} )
	{
	    $ds->{attr_cache}{$path}{$key};
	    #return ref $ds->{attr_cache}{$path}{$key} eq 'ARRAY' ?
	    #	@{$ds->{attr_cache}{$path}{$key}} : $ds->{attr_cache}{$path}{$key};
	}
    }
    
    # If no key is given, or an invalid key is given, then return undefined.
    # If no path is given, return undefined.  If the empty string is given for
    # the path, return the root attribute.
    
    return unless $key && defined $NODE_DEF{$key};
    return unless defined $path && $path ne '';
    
    $path = '/' if $path eq '';
    
    return unless exists $ds->{node_attrs}{$path};
    
    # Otherwise, look up what the value should be and store it in the cache.
    
    return $ds->_lookup_node_attr($path, $key);
}


# _lookup_node_attr ( path, key )
# 
# Look up the specified attribute for the given path.  If it is not defined
# for the specified path, look for a parent path.  If it is not defined for
# any of the parents, see if the data service has the specified attribute.
# Because this is an internal routine, we skip the 'defined' checks.

sub _lookup_node_attr {
    
    my ($ds, $path, $key) = @_;
    
    # First create an attribute cache for this path if one does not already exist.
    
    $ds->{attr_cache}{$path} //= {};
    
    # If the attribute is non-heritable, then just cache and return whatever
    # is defined for this node.
    
    if ( $NODE_NONHERITABLE{$key} )
    {
	return $ds->{attr_cache}{$path}{$key} = $ds->{node_attrs}{$path}{$key};
    }
    
    # Otherwise check if the path actually has a value for this attribute.
    # If it does not, or if the corresponding path_compose entry is set, then
    # look up the value for the parent node if there is one.
    
    my $inherited_value;
    
    if ( ! exists $ds->{node_attrs}{$path}{$key} || $ds->{path_compose}{$path}{$key} )
    {
	my $parent = $ds->path_parent($path);
	
	# If we have a parent, look up the attribute there and put the value
	# in the cache for the current path.
	
	if ( defined $parent )
	{
	    $inherited_value = $ds->_lookup_node_attr($parent, $key);
	}
	
	# Otherwise, if the attribute is defined in the configuration file
	# then look it up there.
	
	else
	{
	    my $config_value = $ds->config_value($key);
	    
	    if ( defined $config_value )
	    {
		$inherited_value = $config_value;
	    }
	    
	    # If it is not defined in the configuration file, see if we have a
	    # universal default.
	    
	    elsif ( defined $NODE_ATTR_DEFAULT{$key} )
	    {
		$inherited_value = $NODE_ATTR_DEFAULT{$key};
	    }
	    
	    # Otherwise, if this is one of the following attributes, use the
	    # indicated default.
	    
	    elsif ( $key eq 'allow_method' )
	    {
	    	my %default_methods = map { $_ => 1 } @Web::DataService::DEFAULT_METHODS;
	    	$inherited_value = \%default_methods;
	    }
	    
	    elsif ( $key eq 'allow_format' )
	    {
	    	my %default_formats = map { $_ => 1 } @{$ds->{format_list}};
	    	$inherited_value = \%default_formats;
	    }
	    
	    elsif ( $key eq 'allow_vocab' )
	    {
	    	my %default_vocab = map { $_ => 1 } @{$ds->{vocab_list}};
	    	$inherited_value = \%default_vocab;
	    }
	}
	
	# If no value exists for the current path, cache and return the value we
	# just looked up.  Or undef if we didn't find any value.
	
	if ( ! exists $ds->{node_attrs}{$path}{$key} )
	{
	    $ds->{attr_cache}{$path}{$key} = $inherited_value;
	    return $ds->{attr_cache}{$path}{$key};
	}
    }
    
    # If we get here then we need to compose the inherited value with the
    # value from the current node.
    
    my $new_value;
    
    # If the attribute type is 'set', then separate the value by commas.  If
    # we have an inherited value, start with it and add or delete sub-values
    # as indicated.
    
    if ( $NODE_DEF{$key} eq 'set' )
    {
	$new_value = ref $inherited_value eq 'HASH' ? { %$inherited_value } : { };
	my $string_value = $ds->{node_attrs}{$path}{$key} // '';
	
	foreach my $v ( split( /\s*,\s*/, $string_value ) )
	{
	    next unless $v =~ /^([+-])?(.*)/;
	    
	    if ( defined $1 && $1 eq '-' )
	    {
		delete $new_value->{$2};
	    }
	    
	    else
	    {
		$new_value->{$2} = 1;
	    }
	}
    }
    
    # If the attribute type is 'list', then separate the value by commas and
    # create a list.
    
    elsif ( $NODE_DEF{$key} eq 'list' )
    {
	$new_value = [ ];
	my $string_value = $ds->{node_attrs}{$path}{$key} // '';
	
	foreach my $v ( split( /\s*,\s*/, $string_value ) )
	{
	    push @$new_value, $v if defined $v && $v ne '';
	}
    }
    
    # Otherwise, the new value simply overrides any inherited value.  This code
    # path is only here in case path_compose is set mistakenly for some attribute
    # of type 'single'.
    
    else
    {
	$new_value = $ds->{node_attrs}{$path}{$key};
    }
    
    # Stuff the new value into the cache and return it.
    
    return $ds->{attr_cache}{$path}{$key} = $new_value;
}


# path_parent ( path )
# 
# Return the parent path of the given path.  For example, the parent of "a/b"
# is "a".  The parent of "a" is "/".  The parent of "/" or is undefined.  So
# is the parent of "", though that is not a valid path.

sub path_parent {
    
    my ($ds, $path) = @_;
    
    # If $path is defined, we cache the lookup values undef 'path_parent'.
    
    return undef unless defined $path;
    return $ds->{path_parent}{$path} if exists $ds->{path_parent}{$path};
    
    # If not found, add it to the cache and return it.
    
    if ( $path eq '/' || $path eq '' )
    {
	return $ds->{path_parent}{$path} = undef;
    }
    
    elsif ( $path =~ qr{ ^ [^/]+ $ }xs )
    {
	return $ds->{path_parent}{$path} = '/';
    }
    
    elsif ( $path =~ qr{ ^ (.+) / [^/]+ }xs )
    {
	return $ds->{path_parent}{$path} = $1;
    }
    
    else
    {
	return $ds->{path_parent}{$path} = undef;
    }
}


# add_node_doc ( node, doc_string )
# 
# Add the specified documentation string to the specified node.

sub add_node_doc {
    
    my ($ds, $node, $doc) = @_;
    
    return unless defined $doc;
    
    croak "only strings may be added to documentation: '$doc' is not valid"
	if ref $doc;
    
    # If the first documentation string starts with !, mark the node as
    # undocumented and remove the '!'.
    
    unless ( $node->{doc_string} )
    {
	if ( $doc =~ qr{ ^ ! (.*) }xs )
	{
	    $doc = $1;
	    $node->{undocumented} = 1;
	}
    }
    
    # Now add the documentation string.
    
    $node->{doc_string} = '' unless defined $node->{doc_string};
    $node->{doc_string} .= "\n" if $node->{doc_string} ne '' && $doc ne '';
    $node->{doc_string} .= $doc;
}


1;
