# 
# DataService::Output
# 
# 
# 
# Author: Michael McClennen

use strict;

package Web::DataService::Output;

use Encode;
use Scalar::Util qw(reftype);
use Carp qw(carp croak);

use Moo::Role;


sub define_output_map {
    
    goto \&Web::DataService::Set::define_set;
}


# define_block ( name, specification... )
# 
# Define an output block with the specified name, using the given
# specification records.

sub define_block {
    
    my $ds = shift;
    my $name = shift;
    
    # Check to make sure that we were given a valid name.
    
    if ( ref $name )
    {
	croak "define_block: the first argument must be an output block name";
    }
    
    elsif ( not $ds->valid_name($name) )
    {
	croak "define_block: invalid block name '$name'";
    }
    
    # Create a new block object.
    
    my $block = { name => $name,
		  include_list => [],
		  output_list => [] };
    
    $ds->{block}{$name} = bless $block, 'Web::DataService::Block';
    
    # Then process the records one by one.  Make sure to throw an error if we
    # find a record whose type is ambiguous or that is otherwise invalid.  Each
    # record gets put in a list that is stored under the section name.
    
    foreach my $item (@_)
    {
	# A scalar is interpreted as a documentation string.
	
	unless ( ref $item )
	{
	    $ds->add_doc($block, $item);
	    next;
	}
	
	# Any item that is not a hashref is an error.
	
	unless ( ref $item eq 'HASH' )
	{
	    croak "the arguments to 'output_section' must be hashrefs or scalars";
	}
	
	# Check the output record to make sure it was specified correctly.
	
	my ($type) = $ds->check_output_record($item);
	
	# If the type is 'field', then any subsequent documentation strings
	# will be added to that record.
	
	$ds->add_doc($block, $item) if $type eq 'output';
	
	# Add the record to the appropriate list.
	
	if ( $type eq 'include' )
	{
	    push @{$ds->{block}{$name}{include_list}}, $item;
	}
	
	else
	{
	    push @{$ds->{block}{$name}{output_list}}, $item;
	}
    }
    
    $ds->process_doc($block);
}


our %OUTPUT_DEF = (output => 'type',
		   set => 'type',
		   select => 'type',
		   filter => 'type',
		   include => 'type',
		   if_block => 'set',
		   not_block => 'set',
		   if_vocab => 'set',
		   not_vocab => 'set',
		   if_format => 'set',
		   not_format => 'set',
		   if_field => 'single',
		   not_field => 'single',
		   if_code => 'code',
		   dedup => 'single',
		   name => 'single',
		   value => 'single',
		   always => 'single',
		   text_join => 'single',
		   xml_join => 'single',
		   show_as_list => 'single',
		   data_type => 'single',
		   sub_record => 'single',
		   from => 'single',
		   from_each => 'single',
		   append => 'single',
		   code => 'code',
		   lookup => 'hash',
		   default => 'single',
		   split => 'regexp',
		   join => 'single',
		   tables => 'set',
		   doc_string => 'single');

our %SELECT_KEY = (select => 1, tables => 1);

our %FIELD_KEY = (dedup => 1, name => 1, value => 1, always => 1, sub_record => 1, if_field => 1, 
		  not_field => 1, if_block => 1, not_block => 1, if_format => 1, not_format => 1,
		  if_vocab => 1, not_vocab => 1,
		  text_join => 1, xml_join => 1, doc_string => 1, show_as_list => 1, undocumented => 1);

our %PROC_KEY = (set => 1, append => 1, from => 1, from_each => 1, 
		 if_vocab => 1, not_vocab => 1, if_block => 1, not_block => 1,
	         if_format => 1, not_format => 1, if_field => 1, not_field => 1,
		 code => 1, lookup => 1, split => 1, join => 1, default => 1);

sub check_output_record {
    
    my ($ds, $record) = @_;
    
    my $type = '';
    
    foreach my $k (keys %$record)
    {
	my $v = $record->{$k};
	
	if ( $k =~ qr{ ^ (\w+) _ (name|value) $ }x )
	{
	    croak "define_output: unknown format or vocab '$1' in '$k'"
		unless defined $ds->{vocab}{$1} || defined $ds->{format}{$1};
	}
	
	elsif ( ! defined $OUTPUT_DEF{$k} )
	{
	    croak "define_output: unrecognized attribute '$k'";
	}
	
	elsif ( $OUTPUT_DEF{$k} eq 'type' )
	{
	    croak "define_output: you cannot have both attributes '$type' and '$k' in one record"
		if $type;
	    
	    $type = $k;
	}
	
	elsif ( $OUTPUT_DEF{$k} eq 'single' )
	{
	    croak "define_output: the value of '$k' must be a scalar" if ref $v;
	}
	
	elsif ( $OUTPUT_DEF{$k} eq 'set' )
	{
	    croak "define_output: the value of '$k' must be an array ref or string"
		if ref $v && reftype $v ne 'ARRAY';
	    
	    unless ( ref $v )
	    {
		$record->{$k} = [ split(qr{\s*,\s*}, $v) ];
	    }
	}
	
	elsif ( $OUTPUT_DEF{$k} eq 'code' )
	{
	    croak "define_output: the value of '$k' must be a code ref"
		unless ref $v && reftype $v eq 'CODE';
	}
	
	elsif ( $OUTPUT_DEF{$k} eq 'hash' )
	{
	    croak "define_output: the value of '$k' must be a hash ref"
		unless ref $v && reftype $v eq 'HASH';
	}
	
	elsif ( $OUTPUT_DEF{$k} eq 'regexp' )
	{
	    croak "define_output: the value of '$k' must be a regexp or string"
		if ref $v && reftype $v ne 'REGEXP';
	}
    }
    
    # Now make sure that each record has a 'type' attribute.
    
    croak "each record passed to define_output must include one attribute from the \
following list: 'include', 'output', 'set', 'select', 'filter'"
	unless $type;
    
    return $type;
}


# _setup_output ( request )
# 
# Determine the list of selection, processing and output rules for the
# specified query, based on the query's attributes.  These attributes include: 
# 
# - the output map
# - the output format
# - the output vocabulary
# - the selected output keys
# 
# Depending upon the attributes of the various output records, all, some or
# none of them may be relevant to a particular query.

sub _setup_output {

    my ($ds, $request) = @_;
    
    # Extract the relevant attributes of the request
    
    my $path = $request->node_path;
    my $format = $request->output_format;
    my $vocab = $request->output_vocab;
    
    my $require_vocab; $require_vocab = 1 if $vocab and not $ds->{vocab}{$vocab}{use_field_names};
    
    # Add fields to the request object to hold the output configuration.
    
    $request->{select_list} = [];
    $request->{select_hash} = {};
    $request->{tables_hash} = {};
    $request->{filter_hash} = {};
    $request->{proc_list} = [];
    $request->{field_list} = [];
    $request->{block_keys} = {};
    $request->{block_hash} = {};
    
    # Use the output and output_opt attributes of the request to determine
    # which output blocks we will be using to express the request result.
    
    # We start with 'output', which specifies a list of blocks that are always
    # included.
    
    my $output_list = $ds->node_attr($path, 'output');
    my @output_list; @output_list = @$output_list if ref $output_list eq 'ARRAY';
    
    my @blocks;
    
    foreach my $block_name ( @output_list )
    {
	if ( ref $ds->{block}{$block_name} eq 'Web::DataService::Block' )
	{
	    push @blocks, $block_name;
	}
	
	else
	{
	    $request->add_warning("Output block '$block_name' not found");
	}
    }
    
    # The special parameter 'show' is used to select optional output blocks.
    
    my @optional_keys = $request->special_value('show');
    
    # The attribute 'optional_output' specifies a map which maps the keys from the
    # output_param value to block names.  We go through the keys one by one
    # and add each key and the name of the associated block to the relevant hash.
    
    my $optional_output = $ds->node_attr($path, 'optional_output');
    my $output_map; $output_map = $ds->{set}{$optional_output} if defined $optional_output && 
	ref $ds->{set}{$optional_output} eq 'Web::DataService::Set';
    
    if ( $output_map )
    {
	foreach my $key ( @optional_keys )
	{
	    next unless defined $key;
	    my $block = $output_map->{value}{$key}{maps_to};
	    $request->{block_keys}{$key} = 1;
	    $request->{block_hash}{$key} = 1;
	    
	    if ( $block && ref $ds->{block}{$block} eq 'Web::DataService::Block' )
	    {
		$request->{block_hash}{$block} = 1;
		push @blocks, $block;
	    }
	    
	    elsif ( $block )
	    {
		$request->add_warning("Output block '$block' not found");
	    }
	}
    }
    
    elsif ( $optional_output )
    {
	$request->add_warning("Output map '$optional_output' not found");
    }
    
    # Now warn the user if no output blocks were specified for this request,
    # because it means that no output will result.
    
    unless ( @blocks )
    {
	$request->add_warning("No output blocks were specified for this request.");
	return;
    }
    
    # Then scan through the list of blocks and check for include_list
    # entries, and add the included blocks to the list as well.  This
    # allows us to know before the rest of the processing exactly which blocks
    # are included.
    
    my %uniq_block;
    
 INCLUDE_BLOCK:
    foreach my $block (@blocks)
    {
	# Make sure that each block is checked only once.
	
	next if $uniq_block{$block}; $uniq_block{$block} = 1;
	
	my $include_list = $ds->{block}{$block}{include_list};
	next unless ref $include_list eq 'ARRAY';
	
      INCLUDE_RECORD:
	foreach my $r ( @$include_list )
	{
	    # Evaluate dependency on the output section list
	    
	    next INCLUDE_RECORD if $r->{if_block} 
		and not check_set($r->{if_block}, $request->{block_hash});
	    
	    next INCLUDE_RECORD if $r->{not_block}
		and check_set($r->{not_block}, $request->{block_hash});
	    
	    # Evaluate dependency on the output format
	    
	    next INCLUDE_RECORD if $r->{if_format}
		and not check_value($r->{if_format}, $format);
	    
	    next INCLUDE_RECORD if $r->{not_format}
		and check_value($r->{not_format}, $format);
	    
	    # Evaluate dependency on the vocabulary
	    
	    next INCLUDE_RECORD if $r->{if_vocab}
		and not check_value($r->{if_vocab}, $vocab);
	    
	    next INCLUDE_RECORD if $r->{not_vocab}
		and check_value($r->{not_vocab}, $vocab);
	    
	    # If the 'include' record specified a key, figure out its
	    # corresponding block if any.
	    
	    my ($include_key, $include_block);
	    
	    if ( ref $output_map->{value}{$r->{include}} )
	    {
		$include_key = $r->{include};
		$include_block = $output_map->{value}{$include_key}{maps_to};
	    }
	    
	    else
	    {
		$include_block = $r->{include};
	    }
	    
	    # Modify the record so that we know what block to include in the
	    # loop below.
	    
	    $r->{include_block} = $include_block if $include_block;
	    
	    # Now add the specified key and block to the output hash, if they
	    # are defined.
	    
	    $request->{block_keys}{$include_key} = 1 if $include_key;
	    $request->{block_hash}{$include_block} = 1 if $include_block;
	    push @blocks, $include_block if $include_block;
	}
    }
    
    # Now run through all of the blocks we have identified and collect up the
    # various kinds of records they contain.
    
    %uniq_block = ();
    
 BLOCK:
    foreach my $block (@blocks)
    {
	# Make sure that each block is only processed once, even if it is
	# listed more than once.
	
	next if $uniq_block{$block}; $uniq_block{$block} = 1;
	
	# Add this block to the output configuration.
	
	$ds->add_output_block($request, $block);
    }
    
    my $a = 1;	# We can stop here when debugging
}


# add_output_block ( request, block_name )
# 
# Add the specified block to the output configuration for the specified
# request. 

sub add_output_block {

    my ($ds, $request, $block_name) = @_;
    
    # Generate a warning if the specified block does not exist, but do
    # not abort the request.
    
    my $block_list = $ds->{block}{$block_name}{output_list};
    
    unless ( ref $block_list eq 'ARRAY' )
    {
	warn "undefined output block '$block_name' for path '$request->{path}'\n";
	$request->add_warning("undefined output block '$block_name'");
	return;
    }
    
    # Extract the relevant request attributes.
    
    my $class = ref $request;
    my $format = $request->output_format;
    my $vocab = $request->output_vocab;
    my $require_vocab; $require_vocab = 1 if $vocab and not $ds->{vocab}{$vocab}{use_field_names};
    
    # Now go through the output list for this block and collect up
    # all records that are selected for this query.
    
    my @records = @$block_list;
    
 RECORD:
    while ( my $r = shift @records )
    {
	# Evaluate dependency on the output block list
	
	next RECORD if $r->{if_block} 
	    and not check_set($r->{if_block}, $request->{block_hash});
	
	next RECORD if $r->{not_block}
	    and check_set($r->{not_block}, $request->{block_hash});
	
	# Evaluate dependency on the output format
	
	next RECORD if $r->{if_format}
	    and not check_value($r->{if_format}, $format);
	
	next RECORD if $r->{not_format}
	    and check_value($r->{not_format}, $format);
	
	# Evaluate dependency on the vocabulary
	
	next RECORD if $r->{if_vocab}
	    and not check_value($r->{if_vocab}, $vocab);
	
	next RECORD if $r->{not_vocab}
	    and check_value($r->{not_vocab}, $vocab);
	
	# If the record type is 'select', add to the selection list, the
	# selection hash, and the tables hash.
	
	if ( $r->{select} )
	{
	    croak "value of 'select' must be a string or array"
		if ref $r->{select} && ref $r->{select} ne 'ARRAY';
	    
	    my @select = ref $r->{select} ? @{$r->{select}}
		: split qr{\s*,\s*}, $r->{select};
	    
	    foreach my $s ( @select )
	    {
		next if exists $request->{select_hash}{$s};
		$request->{select_hash}{$s} = 1;
		push @{$request->{select_list}}, $s;
	    }
	    
	    if ( $r->{tables} )
	    {
		croak "value of 'tables' must be a string or array"
		    if ref $r->{tables} && ref $r->{tables} ne 'ARRAY';
		
		my @tables = ref $r->{tables} ? @{$r->{tables}}
		    : split qr{\s*,\s*}, $r->{tables};
		
		foreach my $t ( @tables )
		{
		    $request->{tables_hash}{$t} = 1;
		}
	    }
	    
	    foreach my $k ( keys %$r )
	    {
		warn "ignored invalid key '$k' in 'select' record"
		    unless $SELECT_KEY{$k};
	    }
	}
	
	# If the record type is 'filter', add to the filter hash.
	
	elsif ( defined $r->{filter} )
	{
	    $request->{filter_hash}{$r->{filter}} = $r->{value};
	}
	
	# If the record type is 'set', add a record to the process list.
	
	elsif ( defined $r->{set} )
	{
	    my $proc = { set => $r->{set} };
	    
	    foreach my $key ( keys %$r )
	    {
		if ( $PROC_KEY{$key} )
		{
		    $proc->{$key} = $r->{$key};
		}
		
		else
		{
		    carp "Warning: unknown key '$key' in proc record\n";
		}
	    }
	    
	    push @{$request->{proc_list}}, $proc;
	}
	
	# If the record type is 'output', add a record to the field list.
	# The attributes 'name' (the output name) and 'field' (the raw
	# field name) are both set to the indicated name by default.
	
	elsif ( defined $r->{output} )
	{
	    next RECORD if $require_vocab and not exists $r->{"${vocab}_name"};
	    
	    my $field = { field => $r->{output}, name => $r->{output} };
	    my ($vs_value, $vs_name);
	    
	    foreach my $key ( keys %$r )
	    {
		if ( $FIELD_KEY{$key} )
		{
		    $field->{$key} = $r->{$key}
			unless ($key eq 'value' && $vs_value) || ($key eq 'name' && $vs_name);
		}
		
		elsif ( $key =~ qr{ ^ (\w+) _ (name|value) $ }x )
		{
		    if ( $1 eq $vocab || $1 eq $format )
		    {
			$field->{$2} = $r->{$key};
			$vs_value = 1 if $2 eq 'value';
			$vs_name = 1 if $2 eq 'name';
		    } 
		}
		
		elsif ( $key eq 'data_type' )
		{
		    my $type_value = $r->{$key};
		    croak "unknown value '$r->{$key}' for data_type: must be one of 'int', 'pos', 'dec'"
			unless lc $type_value eq 'int' || lc $type_value eq 'pos' ||
			    lc $type_value eq 'dec';
		    
		    push @{$request->{proc_list}}, { check => $r->{output}, type => $r->{$key} };
		}
		
		elsif ( $key ne 'output' )
		{
		    warn "Warning: unknown key '$key' in output record\n";
		}
	    }
	    
	    push @{$request->{field_list}}, $field;
	}
	
	# If the record type is 'include', then add the specified records
	# to the list immediately.  If no 'include_block' was
	# specified, that means that the specified key did not correspond
	# to any block.  So we can ignore it in that case.
	
	elsif ( defined $r->{include_block} )
	{
	    # If we have already processed this block, then skip it.  A
	    # block can only be included once per request.  If we haven't
	    # processed it yet, mark it so that it will be skipped if it
	    # comes up again.
	    
	    my $include_block = $r->{include_block};
	    next RECORD if $request->{block_hash}{$include_block};
	    $request->{block_hash}{$include_block} = 1;
	    
	    # Get the list of block records, or add a warning if no block
	    # was defined under that name.
	    
	    my $add_list = $ds->{block}{$include_block}{output_list};
	    
	    unless ( ref $add_list eq 'ARRAY' )
	    {
		warn "undefined output block '$include_block' for path '$request->{path}'\n";
		$request->add_warning("undefined output block '$include_block'");
		next RECORD;
	    }
	    
	    # Now add the included block's records to the front of the
	    # record list.
	    
	    unshift @records, @$add_list;
	}
    }
    
    my $a = 1;	# we can stop here when debugging
}


# get_output_map ( name )
# 
# If the specified name is the name of an output map, return a reference to
# the map.  Otherwise, return undefined.

sub get_output_map {
    
    my ($ds, $output_name) = @_;
    
    if ( ref $ds->{set}{$output_name} eq 'Web::DataService::Set' )
    {
	return $ds->{set}{$output_name};
    }
    
    return;
}


# get_output_block ( name )
# 
# If the specified name is the name of an output block, return a reference to
# the block.  Otherwise, return empty.

sub get_output_block {

    my ($ds, $output_name) = @_;
    
    if ( ref $ds->{block}{$output_name} eq 'Web::DataService::Block' )
    {
	return $ds->{block}{$output_name};
    }
    
    return;
}


# get_output_keys ( request, map )
# 
# Figure out which output keys have been selected for the specified request,
# using the specified output map.

sub get_output_keys {
    
    my ($ds, $request, $output_map) = @_;
    
    my $path = $request->{path};
    
    # Return empty unless we have a map.
    
    return unless ref $output_map eq 'Web::DataService::Set';
    
    # Start with the fixed blocks.
    
    my @keys; @keys = @{$output_map->{fixed}} if ref $output_map->{fixed} eq 'ARRAY';
    
    # Then add the optional blocks.
    
    my $output_param = $ds->{node_attrs}{$path}{output_param};   # re-do
                                                                   # with ->node_attrs
    
    push @keys, @{$request->{params}{$output_param}}
	if defined $output_param and ref $request->{params}{$output_param} eq 'ARRAY';
    
    return @keys;
}


# configure_block ( request, block_name )
# 
# Given a block name, determine the list of output fields and proc fields
# (if any) that are defined for it.  This is used primarily to configure
# blocks referred to via 'sub_record' attributes.
# 
# These lists are stored under the keys 'block_proc_list' and
# 'block_field_list' in the request record.  If these have already been filled
# in for this block, do nothing.

sub configure_block {

    my ($ds, $request, $block_name) = @_;
    
    # Return immediately if the relevant lists have already been computed
    # and cached (even if they are empty).
    
    return 1 if exists $request->{block_field_list}{$block_name};
    
    # Otherwise, we need to compute both lists.  Start by determining the
    # relevant attributes of the request and looking up the output list
    # for this block.
    
    my $format = $request->output_format;
    my $vocab = $request->output_vocab;
    my $require_vocab; $require_vocab = 1 if $vocab and not $ds->{vocab}{$vocab}{use_field_names};
    
    my $block_list = $ds->{block}{$block_name}{output_list};
    
    # If no list is available, indicate this to the request object and return
    # false.  Whichever routine called us will be responsible for generating an
    # error or warning if appropriate.
    
    unless ( ref $block_list eq 'ARRAY' )
    {
	$request->{block_field_list}{$block_name} = undef;
	$request->{block_proc_list}{$block_name} = undef;
	return;
    }
    
    # Go through each record in the list, throwing out the ones that don't
    # apply and assigning the ones that do.
    
    my (@field_list, @proc_list);
    
 RECORD:
    foreach my $r ( @$block_list )
    {
	# Evaluate dependency on the output block list
	
	next RECORD if $r->{if_block} 
	    and not check_set($r->{if_block}, $request->{block_set});
	
	next RECORD if $r->{not_block}
	    and check_set($r->{not_block}, $request->{block_set});
	
	# Evaluate dependency on the output format
	
	next RECORD if $r->{if_format}
	    and not check_value($r->{if_format}, $format);
	
	next RECORD if $r->{not_format}
	    and check_value($r->{not_format}, $format);
	
	# Evaluate dependency on the vocabulary
	
	next RECORD if $r->{if_vocab}
	    and not check_value($r->{if_vocab}, $vocab);
	
	next RECORD if $r->{not_vocab}
	    and check_value($r->{not_vocab}, $vocab);
	
	# If the record type is 'output', add a record to the field list.
	# The attributes 'name' (the output name) and 'field' (the raw
	# field name) are both set to the indicated name by default.
	    
	if ( defined $r->{output} )
	{
	    next RECORD if $require_vocab and not exists $r->{"${vocab}_name"};
	
	    my $output = { field => $r->{output}, name => $r->{output} };
	    
	    foreach my $key ( keys %$r )
	    {
		if ( $FIELD_KEY{$key} )
		{
		    $output->{$key} = $r->{$key};
		}
		
		elsif ( $key =~ qr{ ^ (\w+) _ (name|value) $ }x )
		{
		    $output->{$2} = $r->{$key} if $vocab eq $1;
		}
		
		elsif ( $key ne 'output' )
		{
		    warn "Warning: unknown key '$key' in output record\n";
		}
	    }
	    
	    push @field_list, $output;
	}
	
	# If the record type is 'set', add a record to the proc list.
	
	elsif ( defined $r->{set} )
	{
	    my $proc = { set => $r->{set} };
	    
	    foreach my $key ( keys %$r )
	    {
		if ( $PROC_KEY{$key} )
		{
		    $proc->{$key} = $r->{$key};
		}
		
		else
		{
		    carp "Warning: unknown key '$key' in proc record\n";
		}
	    }
	    
	    push @proc_list, $proc;
	}
	
	# All other record types are ignored.
    }
    
    # Now cache the results.
    
    $request->{block_field_list}{$block_name} = \@field_list;
    $request->{block_proc_list}{$block_name} = \@proc_list;
    
    return 1;
}


# check_value ( list, value )
# 
# Return true if $list is equal to $value, or if it is a list and one if its
# items is equal to $value.

sub check_value {
    
    my ($list, $value) = @_;
    
    return 1 if $list eq $value;
    
    if ( ref $list eq 'ARRAY' )
    {
	foreach my $item (@$list)
	{
	    return 1 if $item eq $value;
	}
    }
    
    return;
}


# check_set ( list, set )
# 
# The parameter $set must be a hashref.  Return true if $list is one of the
# keys of $set, or if it $list is a list and one of its items is a key in
# $set.  A key only counts if it has a true value.

sub check_set {
    
    my ($list, $set) = @_;
    
    return unless ref $set eq 'HASH';
    
    return 1 if $set->{$list};
    
    if ( ref $list eq 'ARRAY' )
    {
	foreach my $item (@$list)
	{
	    return 1 if $set->{$item};
	}
    }
    
    return;
}


# add_doc ( node, item )
# 
# Add the specified item to the documentation list for the specified node.
# The item can be either a string or a record (hashref).

sub add_doc {

    my ($ds, $node, $item) = @_;
    
    # If the item is a record, close any currently pending documentation and
    # start a new "pending" list.  We need to do this because subsequent items
    # may document the record we were just called with.
    
    if ( ref $item )
    {
	croak "cannot add non-hash object to documentation"
	    unless reftype $item eq 'HASH';
	
	$ds->process_doc($node);
	push @{$node->{doc_pending}}, $item;
    }
    
    # If this is a string starting with one of the special characters, then
    # handle it properly.
    
    elsif ( $item =~ qr{ ^ ([!^?] | >>?) (.*) }xs )
    {
	# If >>, then close the active documentation section (if any) and
	# start a new one that is not tied to any rule.  This will generate an
	# ordinary paragraph starting with the remainder of the line.
		
	if ( $1 eq '>>' )
	{
	    $ds->process_doc($node);
	    push @{$node->{doc_pending}}, $2 if $2 ne '';
	}
	
	# If >, then add to the current documentation a blank line
	# (which will cause a new paragraph) followed by the remainder
	# of this line.
	
	elsif ( $1 eq '>' )
	{
	    push @{$node->{doc_pending}}, "\n$2";
	}
	
	# If !, then discard all pending documentation and mark the node as
	# 'undocumented'.  This will cause it to be elided from the documentation.
	
	elsif ( $1 eq '!' )
	{
	    $ds->process_doc($node, 'undocumented');
	}
	
	# If ?, then add the remainder of the line to the documentation.
	# The ! prevents the next character from being interpreted specially.
	
	else
	{
	    push @{$node->{doc_pending}}, $2;
	}
    }
    
    # Otherwise, just add this string to the "pending" list.
    
    else
    {
	push @{$node->{doc_pending}}, $item;
    }
}


# process_doc ( node, disposition )
# 
# Process all pending documentation items.

sub process_doc {

    my ($ds, $node, $disposition) = @_;
    
    # Return immediately unless we have something pending.
    
    return unless ref $node->{doc_pending} eq 'ARRAY' && @{$node->{doc_pending}};
    
    # If the "pending" list starts with an item record, take that off first.
    # Everything else on the list should be a string.
    
    my $primary_item = shift @{$node->{doc_pending}};
    return unless ref $primary_item;
    
    # Discard all pending documentation if the primary item is disabled or
    # marked with a '!'.  In the latter case, note this in the item record.
    
    $disposition //= '';
    
    if ( $primary_item->{disabled} or $primary_item->{undocumented} or
	 $disposition eq 'undocumented' )
    {
	@{$node->{doc_pending}} = ();
	$primary_item->{undocumented} = 1 if $disposition eq 'undocumented';
	return;
    }
    
    # Put the rest of the documentation items together into a single
    # string, which may contain a series of Pod paragraphs.
    
    my $body = '';
    my $last_pod;
    my $this_pod;
    
    while (my $line = shift @{$node->{doc_pending}})
    {
	# If this line starts with =, then it needs extra spacing.
	
	my $this_pod = $line =~ qr{ ^ = }x;
	
	# If $body already has something in it, add a newline first.  Add
	# two if this line starts with =, or if the previously added line
	# did, so that we get a new paragraph.
	
	if ( $body ne '' )
	{
	    $body .= "\n" if $last_pod || $this_pod;
	    $body .= "\n";
	}
	
	$body .= $line;
	$last_pod = $this_pod;
    }
    
    # Then add the documentation to the node's documentation list.  If there
    # is no primary item, add the body as an ordinary paragraph.
    
    unless ( defined $primary_item )
    {
	push @{$node->{doc_list}}, clean_doc($body);
    }
    
    # Otherwise, attach the body to the primary item and add it to the list.
    
    else
    {
	$primary_item->{doc_string} = clean_doc($body, 1);
	push @{$node->{doc_list}}, $primary_item;
    }
}


# clean_doc ( )
# 
# Make sure that the indicated string is valid POD.  In particular, if there
# are any unclosed =over sections, close them at the end.  Throw an exception
# if we find an =item before the first =over or a =head inside an =over.

sub clean_doc {

    my ($docstring, $item_body) = @_;
    
    my $list_level = 0;
    
    while ( $docstring =~ / ^ (=[a-z]+) /gmx )
    {
	if ( $1 eq '=over' )
	{
	    $list_level++;
	}
	
	elsif ( $1 eq '=back' )
	{
	    $list_level--;
	    croak "invalid POD string: =back does not match any =over" if $list_level < 0;
	}
	
	elsif ( $1 eq '=item' )
	{
	    croak "invalid POD string: =item outside of =over" if $list_level == 0;
	}
	
	elsif ( $1 eq '=head' )
	{
	    croak "invalid POD string: =head inside =over" if $list_level > 0 || $item_body;
	}
    }
    
    $docstring .= "\n\n=back" x $list_level;
    
    return $docstring;
}


# document_node ( node, state )
# 
# Return a documentation string for the given node, in Pod format.  This will
# consist of a main item list that may start and stop, possibly with ordinary
# Pod paragraphs in between list chunks.  If this node contains any 'include'
# records, the lists for those nodes will be recursively interpolated into the
# main list.  Sublists can only occur if they are explicitly included in the
# documentation strings for individual node records.
# 
# If the $state parameter is given, it must be a hashref containing any of the
# following keys:
# 
# namespace	A hash ref in which included nodes may be looked up by name.
#		If this is not given, then 'include' records are ignored.
# 
# items_only	If true, then ordinary paragraphs will be ignored and a single
#		uninterrupted item list will be generated.
# 

sub document_node {
    
    my ($ds, $node, $state) = @_;
    
    # Return the empty string unless documentation has been added to this
    # node. 
    
    return '' unless ref $node && ref $node->{doc_list} eq 'ARRAY';
    
    # Make sure we have a state record, if we were not passed one.
    
    $state ||= {};
    
    # Make sure that we process each node only once, if it should happen
    # to be included multiple times.  Also keep track of our recursion level.
    
    return if $state->{processed}{$node->{name}};
    
    $state->{processed}{$node->{name}} = 1;
    $state->{level}++;
    
    # Go through the list of documentation items, treating each one as a Pod
    # paragraph.  That means that they will be separated from each other by a
    # blank line.  List control paragraphs "=over" and "=back" will be added
    # as necessary to start and stop the main item list.
    
    my $doc = '';
    
 ITEM:
    foreach my $item ( @{$node->{doc_list}} )
    {
	# A string is added as an ordinary paragraph.  The main list is closed
	# if it is open.  But the item is skipped if we were given the
	# 'items_only' flag.
	
	unless ( ref $item )
	{
	    next ITEM if $state->{items_only};
	    
	    if ( $state->{in_list} )
	    {
		$doc .= "\n\n" if $doc ne '';
		$doc .= "=back";
		$state->{in_list} = 0;
	    }
	    
	    $doc .= "\n\n" if $doc ne '' && $item ne '';
	    $doc .= $item;
	}
	
	# An 'include' record inserts the documentation for the specified
	# node.  This does not necessarily end the list, only if the include
	# record itself has a documentation string.  Skip the inclusion if no
	# hashref was provided for looking up item names.
	
	elsif ( defined $item->{include} )
	{
	    next ITEM unless ref $state->{namespace} && reftype $state->{namespace} eq 'HASH';
	    
	    if ( defined $item->{doc_string} and $item->{doc_string} ne '' and not $state->{items_only} )
	    {
		if ( $state->{in_list} )
		{
		    $doc .= "\n\n" if $doc ne '';
		    $doc .= "=back";
		    $state->{in_list} = 0;
		}
		
		$doc .= "\n\n" if $doc ne '';
		$doc .= $item->{doc_string};
	    }
	    
	    my $included_node = $state->{namespace}{$item->{include}};
	    
	    next unless ref $included_node && reftype $included_node eq 'HASH';
	    
	    my $subdoc = $ds->document_node($included_node, $state);
	    
	    $doc .= "\n\n" if $doc ne '' && $subdoc ne '';
	    $doc .= $subdoc;
	}
	
	# Any other record is added as a list item.  Try to figure out the
	# item name as best we can.
	
	else
	{
	    my $name = ref $node eq 'Web::DataService::Set' ? $item->{value}
		     : defined $item->{name}		    ? $item->{name}
							    : '';
	    
	    $name ||= '';
	    
	    unless ( $state->{in_list} )
	    {
		$doc .= "\n\n" if $doc ne '';
		$doc .= "=over";
		$state->{in_list} = 1;
	    }
	    
	    $doc .= "\n\n=item $name";
	    $doc .= "\n\n$item->{doc_string}" if defined $item->{doc_string} && $item->{doc_string} ne '';
	}
    }
    
    # If we get to the end of the top-level ruleset and we are still in a
    # list, close it.  Also make sure that our resulting documentation string
    # ends with a newline.
    
    if ( --$state->{level} == 0 )
    {
	$doc .= "\n\n=back" if $state->{in_list};
	$state->{in_list} = 0;
	$doc .= "\n";
    }
    
    return $doc;
}


# document_response ( )
# 
# Generate documentation in Pod format describing the available output fields
# for the specified URL path.

sub document_response {
    
    my ($ds, $path) = @_;
    
    my @blocks;
    my @labels;
    
    # First collect up a list of all of the fixed (non-optional) blocks.
    # Block names that do not correspond to any defined block are ignored,
    # with a warning.
    
    my $output_list = $ds->node_attr($path, 'output') // [ ];
    my $fixed_label = $ds->node_attr($path, 'output_label') // 'basic';
    
    foreach my $block_name ( @$output_list )
    {
	if ( ref $ds->{block}{$block_name} eq 'Web::DataService::Block' )
	{
	    push @blocks, $block_name;
	    push @labels, $fixed_label;
	}
	
	elsif ( $ds->debug )
	{
	    warn "WARNING: block '$block_name' not found"
		unless $Web::DataService::QUIET || $ENV{WDS_QUIET};
	}
    }
    
    # Then add all of the optional blocks, if an output_opt map was
    # specified.
    
    my $optional_output = $ds->node_attr($path, 'optional_output');
    
    if ( $optional_output && ref $ds->{set}{$optional_output} eq 'Web::DataService::Set' )
    {
	my $output_map = $ds->{set}{$optional_output};
	my @keys; @keys = @{$output_map->{value_list}} if ref $output_map->{value_list} eq 'ARRAY';
	
    VALUE:
	foreach my $label ( @keys )
	{
	    my $block_name = $output_map->{value}{$label}{maps_to};
	    next VALUE unless defined $block_name;
	    next VALUE if $output_map->{value}{$label}{disabled} || 
		$output_map->{value}{$label}{undocumented};
	    
	    if ( ref $ds->{block}{$block_name} eq 'Web::DataService::Block' )
	    {
		push @blocks, $block_name;
		push @labels, $label;
	    }
	}
    }
    
    elsif ( $optional_output && $ds->debug )
    {
	warn "WARNING: output map '$optional_output' not found"
	    unless $Web::DataService::QUIET || $ENV{WDS_QUIET};
    }
    
    # If there are no output blocks specified for this path, return an empty
    # string.
    
    return '' unless @blocks;
    
    # Otherwise, determine the set of vocabularies that are allowed for this
    # path.  If none are specifically selected for this path, then all of the
    # vocabularies defined for this data service are allowed.
    
    my $vocabularies; $vocabularies = $ds->node_attr($path, 'allow_vocab') || $ds->{vocab};	
    
    unless ( ref $vocabularies eq 'HASH' && keys %$vocabularies )
    {
	warn "No output vocabularies were selected for path '$path'" if $ds->debug;
	return '';
    }
    
    my @vocab_list = grep { $vocabularies->{$_} && 
			    ref $ds->{vocab}{$_} &&
			    ! $ds->{vocab}{$_}{disabled} } @{$ds->{vocab_list}};
    
    unless ( @vocab_list )
    {
	warn "No output vocabularies were selected for path '$path'" if $ds->debug;
	return "";
    }
    
    # Now generate the header for the documentation, in Pod format.  We
    # include the special "=for wds_table_header" line to give PodParser.pm the
    # information it needs to generate an HTML table.
    
    my $doc_string = '';
    my $field_count = scalar(@vocab_list);
    my $field_string = join ' / ', @vocab_list;
    
    if ( $field_count > 1 )
    {
	$doc_string .= "=for wds_table_header Field name*/$field_count | Block!anchor(block:) | Description\n\n";
	$doc_string .= "=over 4\n\n";
	$doc_string .= "=item $field_string\n\n";
    }
    
    else
    {
	$doc_string .= "=for wds_table_header Field name* | Block | Description\n\n";
	$doc_string .= "=over 4\n\n";
    }
    
    # Run through each block one at a time, documenting all of the fields in
    # the corresponding field list.
    
    my %uniq_block;
    
    foreach my $i (0..$#blocks)
    {
	my $block_name = $blocks[$i];
	my $block_label = $labels[$i];
	
	# Make sure to only process each block once, even if it is listed more
	# than once.
	
	next if $uniq_block{$block_name}; $uniq_block{$block_name} = 1;
	
	my $output_list = $ds->{block}{$block_name}{output_list};
	next unless ref $output_list eq 'ARRAY';
	
	foreach my $r (@$output_list)
	{
	    next unless defined $r->{output};
	    $doc_string .= $ds->document_field($block_label, \@vocab_list, $r)
		unless $r->{undocumented};
	}
    }
    
    $doc_string .= "\n=back\n\n";
    
    return $doc_string;
}


sub document_summary {

    my ($ds, $path) = @_;
    
    # Return the empty string unless a summary block was defined for this path.
    
    my $summary_block = $ds->node_attr($path, 'summary');
    return '' unless $summary_block;
    
    # Otherwise, determine the set of vocabularies that are allowed for this
    # path.  If none are specifically selected for this path, then all of the
    # vocabularies defined for this data service are allowed.
    
    my $vocabularies; $vocabularies = $ds->node_attr($path, 'allow_vocab') || $ds->{vocab};	
    
    unless ( ref $vocabularies eq 'HASH' && keys %$vocabularies )
    {
	return '';
    }
    
    my @vocab_list = grep { $vocabularies->{$_} && 
			    ref $ds->{vocab}{$_} &&
			    ! $ds->{vocab}{$_}{disabled} } @{$ds->{vocab_list}};
    
    unless ( @vocab_list )
    {
	return "";
    }
    
    # Now generate the header for the documentation, in Pod format.  We
    # include the special "=for wds_table_header" line to give PodParser.pm the
    # information it needs to generate an HTML table.
    
    my $doc_string = '';
    my $field_count = scalar(@vocab_list);
    my $field_string = join ' / ', @vocab_list;
    
    if ( $field_count > 1 )
    {
	$doc_string .= "=for wds_table_header Field name*/$field_count | Block!anchor(block:) | Description\n\n";
	$doc_string .= "=over 4\n\n";
	$doc_string .= "=item $field_string\n\n";
    }
    
    else
    {
	$doc_string .= "=for wds_table_header Field name* | Block | Description\n\n";
	$doc_string .= "=over 4\n\n";
    }
    
    # Now determine the summary output list.
    
    my $output_list = $ds->{block}{$summary_block}{output_list};
    return '' unless ref $output_list eq 'ARRAY';
    
    foreach my $r (@$output_list)
    {
	next unless defined $r->{output};
	$doc_string .= $ds->document_field('summary', \@vocab_list, $r)
	    unless $r->{undocumented};
    }
    
    $doc_string .= "\n=back\n\n";
    
    return $doc_string;
}


sub document_field {
    
    my ($ds, $block_key, $vocab_list, $r) = @_;
    
    my @names;
    
    foreach my $v ( @$vocab_list )
    {
	my $n = defined $r->{"${v}_name"}	    ? $r->{"${v}_name"}
	      : defined $r->{name}		    ? $r->{name}
	      : $ds->{vocab}{$v}{use_field_names} ? $r->{output}
	      :					      '';
	
	push @names, $n
    }
    
    my $names = join ' / ', @names;
    
    my $descrip = $r->{doc_string} || "";
    
    if ( defined $r->{if_block} )
    {
	if ( ref $r->{if_block} eq 'ARRAY' )
	{
	    $block_key = join(', ', @{$r->{if_block}});
	}
	else
	{
	    $block_key = $r->{if_block};
	}
    }
    
    my $line = "\n=item $names ( $block_key )\n\n$descrip\n";
    
    return $line;
}


# process_record ( request, record, steps )
# 
# Execute any per-record processing steps that have been defined for this
# record. 

sub process_record {
    
    my ($ds, $request, $record, $steps) = @_;
    
    # If there are no processing steps to do, return immediately.
    
    return unless ref $steps eq 'ARRAY' and @$steps;
    
    # Otherwise go through the steps one by one.
    
    foreach my $p ( @$steps )
    {
	# If this step is a 'check' step, then do the check.
	
	if ( exists $p->{check} )
	{
	    $ds->check_field_type($record, $p->{check}, $p->{type}, $p->{subst});
	    next;
	}
	
	# Figure out which field (if any) we are affecting.  A value of '*'
	# means to use the entire record (only relevant with 'code').
	
	my $set_field = $p->{set};
	
	# Figure out which field (if any) we are looking at.  Skip this
	# processing step if the source field is empty, unless the attribute
	# 'always' is set.
	
	my $source_field = $p->{from} || $p->{from_each} || $p->{set};
	
	# Skip any processing step if the record does not have a non-empty
	# value in the corresponding field (unless the 'always' attribute is
	# set).
	
	if ( $source_field && $source_field ne '*' && ! $p->{always} )
	{
	    next unless defined $record->{$source_field};
	    next if ref $record->{$source_field} eq 'ARRAY' && @{$record->{$source_field}} == 0;
	}
	
	# Skip this processing step based on a conditional field value, if one
	# is defined.
	
	if ( my $cond_field = $p->{if_field} )
	{
	    next unless defined $record->{$cond_field};
	    next if ref $record->{$cond_field} eq 'ARRAY' && @{$record->{$cond_field}} == 0;
	}
	
	elsif ( $cond_field = $p->{not_field} )
	{
	    next if defined $record->{$cond_field} && ref $record->{$cond_field} ne 'ARRAY';
	    next if ref $record->{$cond_field} eq 'ARRAY' && @{$record->{$cond_field}} > 0;
	}
	
	# Now generate a list of result values, according to the attributes of this
	# processing step.
	
	my @result;
	
	# If we have a 'code' attribute, then call it.
	
	if ( ref $p->{code} eq 'CODE' )
	{
	    if ( $source_field eq '*' )
	    {
		@result = $p->{code}($request, $record);
	    }
	    
	    elsif ( $p->{from_each} )
	    {
		@result = map { $p->{code}($request, $_) } 
		    (ref $record->{$source_field} eq 'ARRAY' ? 
		     @{$record->{$source_field}} : $record->{$source_field});
	    }
	    
	    elsif ( $p->{from} )
	    {
		@result = $p->{code}($request, $record->{$source_field});
	    }
	    
	    else
	    {
		@result = $p->{code}($request, $record->{$set_field});
	    }
	}
	
	# If we have a 'lookup' attribute, then use it.
	
	elsif ( ref $p->{lookup} eq 'HASH' )
	{
	    if ( $p->{from_each} )
	    {
		if ( ref $record->{$source_field} eq 'ARRAY' )
		{
		    @result = map { $p->{lookup}{$_} // $p->{default} } @{$record->{$source_field}};
		}
		elsif ( ! ref $record->{$source_field} )
		{
		    @result = $p->{lookup}{$record->{$source_field}} // $p->{default};
		}
	    }
	    
	    elsif ( $p->{from} )
	    {
		@result = $p->{lookup}{$record->{$source_field}} // $p->{default}
		    unless ref $record->{$source_field};
	    }
	    
	    elsif ( $set_field ne '*' && ! ref $record->{$set_field} )
	    {
		@result = $p->{lookup}{$record->{$set_field}} // $p->{default} if defined $record->{$set_field};
	    }
	}
	
	# If we have a 'split' attribute, then use it.
	
	elsif ( defined $p->{split} )
	{
	    if ( $p->{from_each} )
	    {
		if ( ref $record->{$source_field} eq 'ARRAY' )
		{
		    @result = map { split($p->{split}, $_) } @{$record->{$source_field}};
		}
		elsif ( ! ref $record->{$source_field} )
		{
		    @result = split($p->{split}, $record->{$source_field});
		}
	    }
	    
	    elsif ( $p->{from} )
	    {
		@result = split $p->{split}, $record->{$source_field}
		    if defined $record->{$source_field} && ! ref $record->{$source_field};
	    }
	    
	    elsif ( $set_field ne '*' )
	    {
		@result = split $p->{split}, $record->{$set_field}
		    if defined $record->{$set_field} && ! ref $record->{$set_field};
	    }
	}
	
	# If we have a 'join' attribute, then use it.
	
	elsif ( defined $p->{join} )
	{
	    if ( $source_field )
	    {
		@result = join($p->{join}, @{$record->{$source_field}})
		    if ref $record->{$source_field} eq 'ARRAY';
	    }
	    
	    elsif ( $set_field ne '*' )
	    {
		@result = join($p->{join}, @{$record->{$set_field}})
		    if ref $record->{$set_field} eq 'ARRAY';
	    }
	}
	
	# Otherwise, we just use the vaoue of the source field.
	
	else
	{
	    @result = ref $record->{$source_field} eq 'ARRAY' ?
		@{$record->{$source_field}} : $record->{$source_field};
	}
	
	# If the value of 'set' is '*', then we're done.  This is generally
	# only used to call a procedure with side effects.
	
	next if $set_field eq '*';
	
	# Otherwise, use the value to modify the specified field of the record.
	
	# If the attribute 'append' is set, then append to the specified field.
	# Convert the value to an array if it isn't already.
	
        if ( $p->{append} )
	{
	    $record->{$set_field} = [ $record->{$set_field} ] if defined $record->{$set_field}
		and ref $record->{$set_field} ne 'ARRAY';
	    
	    push @{$record->{$set_field}}, @result;
	}
	
	else
	{
	    if ( @result == 1 )
	    {
		($record->{$set_field}) = @result;
	    }
	    
	    elsif ( @result > 1 )
	    {
		$record->{$set_field} = \@result;
	    }
	    
	    elsif ( not $p->{always} )
	    {
		delete $record->{$set_field};
	    }
	    
	    else
	    {
		$record->{$set_field} = '';
	    }
	}
    }    
}


# check_field_type ( record, field, type, subst )
# 
# Make sure that the specified field matches the specified data type.  If not,
# substitute the specified value.

sub check_field_type {

    my ($ds, $record, $field, $type, $subst) = @_;
    
    return unless defined $record->{$field};
    
    if ( $type eq 'int' )
    {
	return if $record->{$field} =~ qr< ^ -? [1-9][0-9]* $ >x;
    }
    
    elsif ( $type eq 'pos' )
    {
	return if $record->{$field} =~ qr< ^ [1-9][0-9]* $ >x;
    }
    
    elsif ( $type eq 'dec' )
    {
	return if $record->{$field} =~ qr< ^ -? (?: [1-9][0-9]* (?: \. [0-9]* )? | [0]? \. [0-9]+ | [0] \. ) $ >x;
    }
    
    elsif ( $type eq 'sci' )
    {
	return if $record->{$field} =~ qr< ^ -? (?: [1-9][0-9]* \. [0-9]* | [0]? \. [0-9]+ | [0] \. ) (?: [eE] -? [1-9][0-9]* ) $ >x;
    }
    
    # If the data type is something we don't recognize, don't do any check.
    
    else
    {
	return;
    }
    
    # If we get here, then the value failed the test.  If we were given a
    # replacement value, substitute it.  Otherwise, just delete the field.
    
    if ( defined $subst )
    {
	$record->{$field} = $subst;
    }
    
    else
    {
	delete $record->{$field};
    }
}


# _generate_single_result ( request )
# 
# This function is called after an operation is executed and returns a single
# record.  Return this record formatted as a single string according to the
# specified output format.

sub _generate_single_result {

    my ($ds, $request) = @_;
    
    # Determine the output format and figure out which class implements it.
    
    my $format = $request->output_format;
    my $format_class = $ds->{format}{$format}{package};
    
    die "could not generate a result in format '$format': no implementing module was found"
	unless $format_class;
    
    # Set the result count to 1, in case the client asked for it.
    
    $request->{result_count} = 1;
    
    # Get the lists that specify how to process each record and which fields
    # to output.
    
    my $proc_list = $request->{proc_list};
    my $field_list = $request->{field_list};
    
    # Generate the initial part of the output, before the first record.
    
    my $output = $format_class->emit_header($request, $field_list);
    
    # If there are any processing steps to do, then do them.
    
    $ds->process_record($request, $request->{main_record}, $proc_list);
    
    # If there is an output_record_hook defined for this path, call it now.
    # If it returns false, do not output the record.
    
    if ( $request->{output_record_hook} )
    {
	$ds->call_hook($request->{output_record_hook}, $request, $request->{main_record})
	    or return;
    }
    
    # Generate the output corresponding to our single record.
    
    $output .= $format_class->emit_record($request, $request->{main_record}, $field_list);
    
    # Generate the final part of the output, after the last record.
    
    $output .= $format_class->emit_footer($request, $field_list);
    
    return $output;
}


# _generate_compound_result ( request )
# 
# This function is called after an operation is executed.  It serializes each
# result record according to the specified output format and returns the
# resulting string.  If $streaming_threshold is specified, and if the size of
# the output exceeds this threshold, this routine then sets up to stream the
# rest of the output.

sub _generate_compound_result {

    my ($ds, $request, $streaming_threshold) = @_;
    
    # Determine the output format and figure out which class implements it.
    
    my $format = $request->output_format;
    my $format_class = $ds->{format}{$format}{package};
    
    die "could not generate a result in format '$format': no implementing module was found"
	unless $format_class;
    
    # Get the lists that specify how to process each record and which fields
    # to output.
    
    my $proc_list = $request->{proc_list};
    my $field_list = $request->{field_list};
    
    # If we have an explicit result list, then we know the count.
    
    $request->{result_count} = scalar(@{$request->{main_result}})
	if ref $request->{main_result};
    
    # Generate the initial part of the output, before the first record.
    
    my $output = $format_class->emit_header($request, $field_list);
    
    # A record separator is emitted before every record except the first.  If
    # this format class does not define a record separator, use the empty
    # string.
    
    $request->{rs} = $format_class->can('emit_separator') ?
	$format_class->emit_separator($request) : '';
    
    my $emit_rs = 0;
    
    $request->{actual_count} = 0;
    
    # If an offset was specified and the result method didn't handle this
    # itself, then skip the specified number of records.
    
    if ( defined $request->{result_offset} && $request->{result_offset} > 0
	 && ! $request->{offset_handled} )
    {
	$ds->_next_record($request) foreach 1..$request->{result_offset};
    }
    
    # Now fetch and process each output record in turn.  If output streaming is
    # available and our total output size exceeds the threshold, switch over
    # to streaming.
    
    while ( my $record = $ds->_next_record($request) )
    {
	# If there are any processing steps to do, then process this record.
	
	$ds->process_record($request, $record, $proc_list);
	
	# If there is an output_record_hook defined for this path, call it now.
	# If it returns false, do not output the record.
	
	if ( $request->{output_record_hook} )
	{
	    $ds->call_hook($request->{output_record_hook}, $request, $request->{main_record})
		or return;
	}
	
	# Generate the output for this record, preceded by a record separator if
	# it is not the first record.
	
	$output .= $request->{rs} if $emit_rs; $emit_rs = 1;
	
	$output .= $format_class->emit_record($request, $record, $field_list);
	
	# Keep count of the output records, and stop if we have exceeded the
	# limit.
	
	if ( defined $request->{result_limit} && $request->{result_limit} ne 'all' )
	{
	    last if ++$request->{actual_count} >= $request->{result_limit};
	}
	
	# If streaming is a possibility, check whether we have passed the
	# threshold for result size.  If so, then we need to immediately
	# stash the output generated so far and call stream_data.  Doing that
	# will cause the current function to be aborted, followed by an
	# automatic call to &stream_result (defined below).
	
	if ( defined $streaming_threshold && length($output) > $streaming_threshold )
	{
	    $request->{stashed_output} = $output;
	    Dancer::Plugin::StreamData::stream_data($request, &_stream_compound_result);
	}
    }
    
    # If we get here, then we did not initiate streaming.  So add the
    # footer and return the output data.
    
    # Generate the final part of the output, after the last record.
    
    $output .= $format_class->emit_footer($request, $field_list);
    
    # Determine if we need to encode the output into the proper character set.
    # Usually Dancer does this for us, but only if it recognizes the content
    # type as text.  For these formats, the definition should set the
    # attribute 'encode_as_text' to true.
    
    my $output_charset = $ds->{_config}{charset};
    my $must_encode;
    
    if ( $output_charset 
	 && $ds->{format}{$format}{encode_as_text}
	 && ! $request->{content_type_is_text} )
    {
	$must_encode = 1;
    }
    
    return $must_encode ? encode($output_charset, $output) : $output;
}

    # If the flag 'process_resultset' is set, then we need to fetch and
    # process the entire result set before generating output.  Obviously,
    # streaming is not a possibility in this case.
    
    # if ( $ds->{process_resultset} )
    # {
    # 	my @rows;
	
    # 	if ( $ds->{main_sth} )
    # 	{
    # 	    while ( $record = $ds->{main_sth}->fetchrow_hashref )
    # 	    {
    # 		push @rows, $record;
    # 	    }
    # 	}
	
    # 	else
    # 	{
    # 	    @rows = @{$ds->{main_result}}
    # 	}
	
    # 	my $newrows = $ds->{process_resultset}(\@rows);
	
    # 	if ( ref $newrows eq 'ARRAY' )
    # 	{
    # 	    foreach my $record (@$newrows)
    # 	    {
    # 		$ds->processRecord($record, $ds->{proc_list});
    # 		my $record_output = $ds->emitRecord($record, is_first => $first_row);
    # 		$output .= $record_output;
		
    # 		$first_row = 0;
    # 		$ds->{row_count}++;
    # 	    }
    # 	}
    # }


# _stream_compound_result ( )
# 
# Continue to generate a compound query result from where
# generate_compound_result() left off, and stream it to the client
# record-by-record.
# 
# This routine must be passed a Plack 'writer' object, to which will be
# written in turn the stashed output from generate_compound_result(), each
# subsequent record, and then the footer.  Each of these chunks of data will
# be immediately sent off to the client, instead of being marshalled together
# in memory.  This allows the server to send results up to hundreds of
# megabytes in length without bogging down.

sub _stream_compound_result {
    
    my ($request, $writer) = @_;
    
    my $ds = $request->{ds};
    
    # Determine the output format and figure out which class implements it.
    
    my $format = $request->output_format;
    my $format_class = $ds->{format}{$format}{package};
    my $format_is_text = $ds->{format}{$format}{is_text};
    
    croak "could not generate a result in format '$format': no implementing class"
	unless $format_class;
    
    # Determine the output character set, because we will need to encode text
    # responses in it.
    
    my $output_charset = $ds->{_config}{charset};
    
    #return $must_encode ? encode($output_charset, $output) : $output;
    
    # First send out the partial output previously stashed by
    # generate_compound_result().
    
    if ( $output_charset && $format_is_text )
    {
	$writer->write( encode($output_charset, $ds->{stashed_output}) );
    }
    
    else
    {
	$writer->write( $ds->{stashed_output} );
    }
    
    # Then process the remaining rows.
    
    while ( my $record = $ds->_next_record($request) )
    {
	# If there are any processing steps to do, then process this record.
	
	$ds->process_record($request, $record, $request->{proc_list});
	
	# If there is an output_record_hook defined for this path, call it now.
	# If it returns false, do not output the record.
	
	if ( $request->{output_record_hook} )
	{
	    $ds->call_hook($request->{output_record_hook}, $request, $request->{main_record})
		or return;
	}
	
	# Generate the output for this record, preceded by a record separator
	# since we are always past the first record once we have switched over
	# to streaming.
	
	my $output = $request->{rs};
	
	$output .= $format_class->emit_record($request, $record);
	
	unless ( defined $output and $output ne '' )
	{
	    # do nothing
	}
	
	elsif ( $output_charset && $format_is_text )
	{
	    $writer->write( encode($output_charset, $output) );
	}
	
	else
	{
	    $writer->write( $output );
	}
	
	# Keep count of the output records, and stop if we have exceeded the
	# limit. 
	
	last if $request->{result_limit} ne 'all' && 
	    ++$request->{actual_count} >= $request->{result_limit};
    }
    
    # finish output...
    
    # my $final = $ds->finishOutput();
    # $writer->write( encode_utf8($final) ) if defined $final and $final ne '';
    
    # Finally, send out the footer and then close the writer object.
    
    my $footer = $format_class->emit_footer($request);
    
    $writer->write( encode_utf8($footer) ) if defined $footer and $footer ne '';
    $writer->close();
}


# _next_record ( request )
# 
# Return the next record to be output for the given request.  If
# $ds->{main_result} is set, use that first.  Once that is exhausted (or if
# it was never set) then if $result->{main_sth} is set then read records from
# it until exhausted.

sub _next_record {
    
    my ($ds, $request) = @_;
    
    # If the result limit is 0, return nothing.  This prevents any records
    # from being returned.
    
    return if defined $request->{result_limit} && $request->{result_limit} eq '0';
    
    # If we have a 'main_result' array with something in it, return the next
    # item in it.
    
    if ( ref $request->{main_result} eq 'ARRAY' and @{$request->{main_result}} )
    {
	return shift @{$request->{main_result}};
    }
    
    # Otherwise, if we have a 'main_sth' statement handle, read the next item
    # from it.
    
    elsif ( ref $request->{main_sth} )
    {
	return $request->{main_sth}->fetchrow_hashref
    }
    
    else
    {
	return;
    }
}


# _generate_empty_result ( request )
# 
# This function is called after an operation is executed and returns no results
# at all.  Return the header and footer only.

sub _generate_empty_result {
    
    my ($ds, $request) = @_;
    
    # Determine the output format and figure out which class implements it.
    
    my $format = $request->output_format;
    my $format_class = $ds->{format}{$format}{package};
    
    croak "could not generate a result in format '$format': no implementing class"
	unless $format_class;
    
    # Call the appropriate methods from this class to generate the header,
    # and footer.
    
    my $output = $format_class->emit_header($request);
    
    $output .= $format_class->emit_footer($request);
    
    return $output;
}


1;
