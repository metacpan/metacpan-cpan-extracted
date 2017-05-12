#
# Web::DataService::JSON
# 
# This module is responsible for putting data responses into JSON format.
# 
# Author: Michael McClennen

use strict;

package Web::DataService::Plugin::JSON;

use JSON;
use Encode;
use Scalar::Util qw(reftype);
use Carp qw(croak);

use parent 'Exporter';

our @EXPORT_OK = qw(json_list_value json_clean);


# emit_header ( request, field_list )
# 
# Return the initial text of a JSON result.

sub emit_header {

    my ($class, $request, $field_list) = @_;
    
    my $output = '{' . "\n";
    
    # Check if we have been asked to report the data source and parameters.
    
    if ( $request->display_datainfo )
    {
	my $info = $request->data_info;
	
	foreach my $key ( $request->data_info_keys )
	{
	    next unless $info->{$key};
	    my $value = json_clean($info->{$key});
	    
	    $output .= qq{"$key":$value,\n};
	}
	
	#$output .= '"data_provider":' . json_clean($info->{data_provider}) . ",\n";
	#$output .= '"data_source":' . json_clean($info->{data_source}) . ",\n";
	#$output .= '"data_source_url":' . json_clean($base . '/') . ",\n";
	#$output .= '"data_license":' . json_clean($info->{license}) . ",\n";
	#$output .= '"data_license_url":' . json_clean($info->{license_url}) . ",\n";
	#$output .= '"documentation_url":' . json_clean($doc_url) . ",\n";
	#$output .= '"data_url":' . json_clean($data_url) . ",\n";
	#$output .= '"access_time":' . json_clean($info->{access_time}) . ",\n";
	$output .= '"parameters":{' . "\n";
	
	my @display = $request->params_for_display;
	my $sep = '';
	
	while ( @display )
	{
	    my $param = shift @display;
	    my $value = shift @display;
	    
	    next unless defined $param && $param ne '';
	    $value //= '';
	    
	    $output .= $sep; $sep = ",\n";
	    
	    if ( ref $value eq 'ARRAY' )
	    {
		$output .= json_list_value($param, @$value);
	    }
	    
	    else
	    {
		$output .= qq<"$param":"$value">;
	    }
	}
	
	$output .= "\n},\n";
    }
    
    # Check if we have been asked to report the result count, and if it is
    # available.
    
    if ( $request->display_counts )
    {
	my $counts = $request->result_counts;
	
	$output .= '"elapsed_time":' . sprintf("%.3g", $request->{elapsed}) . ",\n";
	$output .= '"records_found":' . json_clean($counts->{found}) . ",\n";
	$output .= '"records_returned":' . json_clean($counts->{returned}) . ",\n";
	$output .= '"record_offset":' . json_clean($counts->{offset}) . ",\n"
	    if defined $counts->{offset} && $counts->{offset} > 0;
    }
    
    # Check if we have any warning messages to convey
    
    if ( my @msgs = $request->warnings )
    {
	$output .= qq<"warnings":[\n>;
	my $sep = '';
	foreach my $m (@msgs)
	{
	    $output .= $sep; $sep = ",\n";
	    $output .= json_clean($m);
	}
	$output .= qq<\n],\n>;
    }
    
    # Check if we have summary data to output.
    
    if ( $request->{summary_data} && $request->{summary_field_list} )
    {
	$output .= qq<"summary": >;
	$output .= $class->emit_object($request, $request->{summary_data}, $request->{summary_field_list}) || '""';
	$output .= ",\n";
    }
    
    # The actual data will go into an array, in a field called "records".
    
    $output .= qq<"records": [\n>;
    return $output;
}


# emit_separator ( )
# 
# Return the record separator string.  This will be output between each
# record, but not before the first one.

sub emit_separator {
    
    return ",\n";
}


# emit_footer ( )
# 
# Return the final text for a JSON result.

sub emit_footer {
    
    my ($class, $request) = @_;
    
    return qq<\n]\n}\n>;
}


# emit_error ( code, errors, warnings )
# 
# Return the formatted output for an error message body in JSON.

sub emit_error {
    
    my ($class, $code, $errors, $warnings) = @_;
    
    unless ( ref $errors eq 'ARRAY' )
    {
	$errors = [ "bad call to 'emit_error'" ];
    }
    
    if ( defined $warnings && ! ref $warnings eq 'ARRAY' )
    {
	$warnings = [ "bad call to 'emit_error'" ];
    }
    
    my $error = '"status_code": ' . $code;
    $error .= ",\n" . json_list_value("errors", @$errors);
    $error .= ",\n" . json_list_value("warnings", @$warnings) if ref $warnings eq 'ARRAY' && @$warnings;
    
    return "{ $error }\n";
}


# emit_record ( request, record, field_list )
# 
# Return the formatted output for a single record in JSON according to the
# specified field list.

sub emit_record {
    
    my ($class, $request, $record, $field_list) = @_;
    
    return $class->emit_object($request, $record, $field_list);
}


# emit_object ( request, record, field_list )
# 
# Generate text that expresses the given record in JSON according to the given
# list of output field specifications.

sub emit_object {

    my ($class, $request, $record, $field_list) = @_;
    
    # Start with an empty string.
    
    my $outrec = '{';
    my $sep = '';
    
    # Go through the rule list, generating the fields one by one.  $field_list
    # may be either an array of rule records or a single one.
    
    foreach my $f (reftype $field_list && reftype $field_list eq 'ARRAY' ? @$field_list : $field_list)
    {
	# Skip any field that is empty, unless 'always' or 'value' is set.
	
	my $field = $f->{field};
	
	next unless $f->{always} or defined $f->{value} or 
	    defined $record->{$field} and $record->{$field} ne '';
	
	# Skip any field with a 'dedup' attribute if its value is the same as
	# the value of the field indicated by the attribute.
	
	next if $f->{dedup} and defined $record->{$field} and defined $record->{$f->{dedup}}
	    and $record->{$field} eq $record->{$f->{dedup}};
	
	# Skip any field with a 'if_field' attribute if the corresponding
	# field does not have a true value.
	
	next if $f->{if_field} and not $record->{$f->{if_field}};
	
	# Skip any field with a 'not_field' attribute if the corresponding
	# field has a true value.
	
	next if $f->{not_field} and $record->{$f->{not_field}};
	
	# Start with the initial value for this field.  If it contains a
	# 'value' attribute, use that.  Otherwise, use the indicated field
	# value from the current record.  If that is not defined, use the
	# empty string.
	
	my $value = defined $f->{value}       ? $f->{value} 
	          : defined $record->{$field} ? $record->{$field}
		  :                             '';
	
	# If the field has a 'sub_record' attribute and the value is a hashref then
	# generate output to represent a sub-object by applying the named
	# output section to the value.  If the value is a scalar then this
	# field is silently ignored.
	
	if ( defined $f->{sub_record} )
	{
	    my $ds = $request->ds;
	    $ds->configure_block($request, $f->{sub_record});
	    
	    my $output_list = $request->{block_field_list}{$f->{sub_record}};
	    my $proc_list = $request->{block_proc_list}{$f->{sub_record}};
	    
	    if ( ref $value && reftype $value eq 'HASH' )
	    {
		$request->process_record($value, $proc_list) if $proc_list && @$proc_list;
		
		if ( $output_list && @$output_list )
		{
		    $value = $class->emit_object($request, $value, $output_list);
		}
		else
		{
		    $value = json_clean($value);
		}
	    }
	    
	    # If instead the value is an arrayref then apply the rule to each item
	    # in the list.
	    
	    elsif ( ref $value && reftype $value eq 'ARRAY' )
	    {
		if ( $proc_list && @$proc_list )
		{
		    foreach my $v ( @$value )
		    {
			$request->process_record($v, $proc_list) if $proc_list;
		    }
		}
		
		if ( $output_list && @$output_list )
		{
		    $value = $class->emit_array($request, $value, $output_list);
		}
		else
		{
		    $value = json_clean($value);
		}
	    }
	    
	    else
	    {
		$value = json_clean($value);
	    }
	}
	
	# Otherwise, if the value is an arrayref then we generate output for
	# an array.  If the field is marked "show_as_list", then do this even
	# if there is only one value.
	
	elsif ( ref $value eq 'ARRAY' )
	{
	    $value = $class->emit_array($request, $value);
	}
	
	elsif ( $f->{show_as_list} )
	{
	    $value = $class->emit_array($request, [ $value ]);
	}
	
	# Otherwise just use the value.
	
	else
	{
	    $value = json_clean($value);
	}
	
	# Now, add the value to the growing output.  Add a comma before each
	# record except the first.
	
	my $outkey = $f->{name};
	
	$outrec .= qq<$sep"$outkey":$value>;
	$sep = q<,>;
    }
    
    # If this record has hierarchical children, process them now.  (Do we
    # still need this?)
    
    if ( exists $record->{hier_child} )
    {
	my $children = $class->emit_array($record->{hier_child}, $field_list);
	$outrec .= qq<,"children":$children>;
    }
    
    # Now finish the output string and return it.
    
    $outrec .= '}';
    
    return $outrec;
}


# emit_array ( request, arrayref, field_list )
# 
# Generate text that expresses the given array of values in JSON according to
# the given list of field specifications.

sub emit_array {

    my ($class, $request, $arrayref, $field_list) = @_;
    
    my $f = $field_list if reftype $field_list && reftype $field_list ne 'ARRAY';
    
    # Start with an empty string.
    
    my $outrec = '[';
    my $sep = '';
    
    # Go through the elements of the specified arrayref, applying the
    # specified rule to each one.
    
    my $value = '';
    
    foreach my $elt ( @$arrayref )
    {
	if ( reftype $elt && reftype $elt eq 'ARRAY' )
	{
	    $value = $class->emit_array($request, $elt, $field_list);
	}
	
	elsif ( reftype $elt && reftype $elt eq 'HASH' )
	{
	    next unless $field_list;
	    $value = $class->emit_object($request, $elt, $field_list);
	}
	
	elsif ( ref $elt )
	{
	    next;
	}
	
	else
	{
	    $value = json_clean($elt);
	}
	
	if ( defined $value and $value ne '' )
	{
	    $outrec .= "$sep$value";
	    $sep = ',';
	}
    }
    
    $outrec .= ']';
    
    return $outrec;
}


# json_list_value ( key, @values )
# 
# Return a string representing a JSON key with a list of values.  This is used
# for generating error and warning keys.

sub json_list_value {
    
    my ($key, @values) = @_;
    
    my $output = qq<"$key": [>;
    my $sep = '';
    
    foreach my $m (@values)
    {
	$output .= $sep; $sep = ', ';
	$output .= json_clean($m);
    }
    
    $output .= qq<]>;
}


# json_clean ( string )
# 
# Given a string value, return an equivalent string value that will be valid
# as part of a JSON result.

my (%ESCAPE) = ( '\\' => '\\\\', '"' => '\\"', "\t" => '\\t', "\n" => '\\n',
		 "\r" => '\\r' );	#'

sub json_clean {
    
    my ($string) = @_;
    
    # Return an empty string unless the value is defined.
    
    return '""' unless defined $string and $string ne '';
    
    # Do a quick check for numbers.  If it matches, return the value as-is.
    
    return $string if $string =~ qr{ ^ -? (?: [1-9][0-9]* | 0 ) (?: \. [0-9]+ )? (?: [Ee] -? [0-9]+ )? $ }x;
    
    # Do another quick check for okay characters.  If there's nothing exotic,
    # just return the quoted value.
    
    return '"' . $string . '"' unless $string =~ /[^a-zA-Z0-9 _.,;:<>-]/;
    
    # Otherwise, we need to do some longer processing.
    
    # Turn any numeric character references into actual Unicode characters.
    # The database does contain some of these.
    
    # WARNING: this decoding needs to be checked. $$$
    
    $string =~ s/&\#(\d)+;/decode_utf8(pack("U", $1))/eg;
    
    # Next, escape all backslashes, double-quotes and whitespace control characters
    
    $string =~ s/(\\|\"|\n|\t|\r)/$ESCAPE{$1}/ge;
    
    # Finally, delete all other control characters (they shouldn't be in the
    # database in the first place, but unfortunately some rows do contain
    # them).
    
    $string =~ s/[\0-\037\177]//g;
    
    return '"' . $string . '"';
}


1;
