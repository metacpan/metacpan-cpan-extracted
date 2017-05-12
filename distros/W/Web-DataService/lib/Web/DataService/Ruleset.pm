#
# Web::DataService::Ruleset
# 
# This module provides a role that is used by 'Web::DataService'.  It implements
# routines for handling rulesets.
# 
# Author: Michael McClennen

use strict;

package Web::DataService::Ruleset;

use Carp qw 'croak';
use Try::Tiny;
use Scalar::Util 'reftype';
use Data::Dumper;

use HTTP::Validate qw(:validators);

use Moo::Role;



our @SPECIAL_ALL = qw(show limit offset count vocab datainfo linebreak header);
our @SPECIAL_SINGLE = qw(show vocab datainfo linebreak header);


# define_ruleset ( name, rule... )
# 
# Define a ruleset under the given name.  This is a wrapper around the
# subroutine HTTP::Validate::ruleset, that looks for certain literals and
# replaces them with custom ruleset definitions.

sub define_ruleset {
    
    my $ds = shift;
    
    # The next argument must be the ruleset name.  We restrict these to be
    # valid names according to the Web::DataService pattern.
    
    my $ruleset_name = shift;
    
    croak "define_ruleset: invalid ruleset name '$ruleset_name'\n"
	unless $ruleset_name =~ qr{ ^ [\w.:][\w.:-]* $ }xs;
    
    # Go through the arguments one by one, to see which ones (if any) need to
    # be edited before passing them on to HTTP::Validate.
    
    my @rules_and_doc;
    my $pending_rule;
    my @pending_doc;
    my @final_doc;
    
    my %exclude_special;
    
 ARG:
    foreach my $arg (@_)
    {
	next unless defined $arg;
	
	# Documentation strings are just passed on through.
	
	unless ( ref $arg )
	{
	    push @pending_doc, $arg;
	    next ARG;
	}
	
	# Any reference that is not a hashref should be flagged.
	
	if ( ref $arg ne 'HASH' )
	{
	    croak "define_ruleset: the arguments must be a list of hashrefs and strings\n";
	}
	
	# Otherwise, we have a new rule that needs to be checked.  So first
	# take care of any pending rule and its documentation.
	
	if ( $pending_rule )
	{
	    push @rules_and_doc, $pending_rule, @pending_doc, @final_doc;
	    $pending_rule = undef;
	    @pending_doc = ();
	    @final_doc = ();
	}
	
	# If there is just pending documentation, then add it.
	
	elsif ( @pending_doc )
	{
	    push @rules_and_doc, @pending_doc;
	    @pending_doc = ();
	    @final_doc = ();
	}
	
	# Now we consider the new rule.
	
	$pending_rule = $arg;
	
	# Look at the rule type attribute and its value.  Rules that are not
	# parameter rules are simply passed through.
	
	my $ruletype = $arg->{optional}  ? 'optional' 
		     : $arg->{param}     ? 'param'
		     : $arg->{mandatory} ? 'mandatory'
					 : '';
	
	next ARG unless $ruletype;
	
	my $param = $arg->{$ruletype};
	
	# Now look at the value(s) specified by the 'valid' attribute.
	
	my @valid = ref $arg->{valid} eq 'ARRAY' ? @{$arg->{valid}} 
	          : defined $arg->{valid}        ? $arg->{valid} 
                  :                                ();
	
	foreach my $v ( @valid )
	{
	    # If the value is 'FLAG_VALUE' or 'ANY_VALUE', or a code
	    # reference, then pass it through.
	    
	    next if ref $v eq 'CODE';
	    next if $v eq 'FLAG_VALUE' || $v eq 'ANY_VALUE';
	    
	    # If it is any other kind of reference, throw an exception.
	    
	    if ( ref $v )
	    {
		croak "define_ruleset: invalid validator $v for parameter '$param'\n"
	    }
	    
	    # If it is the name of a set, then replace it with the
	    # corresponding set validator function.  Also add the set's
	    # documentation string to the end of the documentation for this
	    # rule, unless the attribute 'no_set_doc' was also specified.
	    
	    elsif ( $ds->set_defined($v) )
	    {
		$arg->{valid} = $ds->valid_set($v);
		
		unless ( $arg->{no_set_doc} )
		{
		    push @final_doc, $ds->document_set($v);
		}
	    }
	    
	    else
	    {
		croak "define_ruleset: unknown set '$v' for parameter '$param'\n";
	    }
	}
	
	# Delete the attribute 'no_set_doc' if it exists, because HTTP::Validate
	# would reject it.
	
	delete $arg->{no_set_doc};
	
	# Now look for special values of the rule type parameter.
	
	if ( $arg->{$ruletype} =~ qr{ ^ \s* SPECIAL \( ( \s* \w+ \s* ) \) \s* $ }xs )
	{
	    my $special_arg = $1;
	    
	    # If the special parameter is 'all' or 'single', add rules
	    # for all of the special parameters not yet defined in
	    # this ruleset.
	    
	    if ( $special_arg eq 'all' || $special_arg eq 'single' )
	    {
		# Exclude the 'show' parameter, since it must be specified
		# explicitly.
		
		$exclude_special{show} = 1;
		
		# Exclude the 'vocab' parameter unless more than one
		# vocabulary has been defined.
		
		unless ( @{$ds->{vocab_list}} > 1 )
		{
		    $exclude_special{vocab} = 1;
		}
		
		# Exclude the 'header' parameter unless we have a format
		# that uses it.
		
		foreach my $f ( @{$ds->{format_list}} )
		{
		    $exclude_special{header} = 0 if $ds->{format}{$f}{uses_header};
		}
		
		$exclude_special{header} //= 1;
		
		my @remaining_params = grep { $ds->{special}{$_} && ! $exclude_special{$_} }
		    ($special_arg eq 'all' ? @Web::DataService::SPECIAL_ALL 
					   : @Web::DataService::SPECIAL_SINGLE);
		
		foreach my $p ( @remaining_params )
		{
		    push @rules_and_doc, $ds->generate_special_rule($p);
		    push @rules_and_doc, $ds->generate_special_doc($p);
		}
		
		$pending_rule = undef;
	    }
	    
	    # If the rule is 'show' and that parameter is enabled, then just
	    # replace the parameter name and otherwise leave the rule as it
	    # is.  Otherwise, ignore this rule.
	    
	    elsif ( $special_arg eq 'show' )
	    {
		if ( $ds->{special}{show} )
		{
		    $arg->{$ruletype} = $ds->{special}{show};
		    $arg->{list} = ',';
		    @pending_doc = $ds->generate_special_doc($special_arg)
			unless @pending_doc;
		}
		
		else
		{
		    $pending_rule = undef;
		    next ARG;
		}
	    }
	    
	    # Otherwise, replace the rule with the specially generated one.
	    # Add the standard documentation if none was provided.
	    
	    else
	    {
		# Make sure that the parameter name is valid.
		
		croak "define_ruleset: unknown special parameter '$special_arg'\n" unless
		    defined $Web::DataService::SPECIAL_PARAM{$special_arg};
		
		# Ignore this rule if the special parameter is not active.
		
		unless ( $ds->{special}{$special_arg} )
		{
		    $pending_rule = undef;
		    next ARG;
		}
		
		$pending_rule = $ds->generate_special_rule($special_arg);
		@pending_doc = $ds->generate_special_doc($special_arg)
		    unless @pending_doc;
		
		# If the original rule specified any of 'errmsg', 'warn', 
		# 'alias', or 'clean', copy these over to the new rule.
		
		$pending_rule->{errmsg} = $arg->{errmsg} if defined $arg->{errmsg};
		$pending_rule->{warn} = $arg->{warn} if defined $arg->{warn};
		$pending_rule->{alias} = $arg->{alias} if defined $arg->{alias};
		$pending_rule->{clean} = $arg->{clean} if defined $arg->{clean};
		
		# Mark that this parameter has already been dealt with, so
		# that a later rule with 'all' will not include it a second
		# time.
		
		$exclude_special{$special_arg} = 1;
	    }
	}
	
	# Check for an obviously invalid parameter name.
	
	elsif ( $arg->{$ruletype} =~ qr{ SPECIAL | [()] }xs )
	{
	    my $arg_value = $arg->{$ruletype};
	    croak "define_ruleset: syntax error with '$arg_value'\n";
	}
	
	# Otherwise we can just let this rule go through.
    }
    
    # Add the final rule and any pending documentation for it.
    
    if ( $pending_rule )
    {
	push @rules_and_doc, $pending_rule, @pending_doc, @final_doc;
    }
    
    # Now call HTTP::Validate::define_ruleset.  Wrap it in a 'eval' block so
    # that we can catch any errors and pass them to 'croak'.
    
    my $error_msg;
    
    eval {
	
	$ds->{validator}->define_ruleset($ruleset_name, @rules_and_doc);

    };
    
    $error_msg = $@;
    $error_msg =~ s{ \s at \s (?: \S+ Ruleset.pm ) .* }{}xs;
    
    croak "define_ruleset: $error_msg" if $error_msg;
}


# generate_special_rule ( param )
# 
# Generate a rule for the given special parameter.

sub generate_special_rule {
    
    my ($ds, $param) = @_;
    
    # Double check that this parameter is valid.
    
    croak "define_ruleset: the special parameter '$param' is not active\n"
	unless $ds->{special}{$param};
    
    # Start with a basic 'optional' rule.
    
    my $rule = { optional => $ds->{special}{$param} };
    
    # If any aliases were defined for this special parameter, enable them as
    # well.
    
    $rule->{alias} = $ds->{special_alias}{$param}
	if ref $ds->{special_alias}{$param} eq 'ARRAY';
    
    # Add the necessary validator and other attributes.
    
    if ( $param eq 'limit' ) {
	$rule->{valid} = [POS_ZERO_VALUE, ENUM_VALUE('all')];
	$rule->{errmsg} = "acceptable values for 'limit' are a positive integer, 0, or 'all'",
    }
    elsif ( $param eq 'offset' ) {
	$rule->{valid} = POS_ZERO_VALUE;
    }
    elsif ( $param eq 'count' || $param eq 'datainfo' || $param eq 'header' ) {
	$rule->{valid} = FLAG_VALUE;
    }
    elsif ( $param eq 'linebreak' ) {
	$rule->{valid} = ENUM_VALUE('cr', 'crlf');
    }
    elsif ( $param eq 'vocab' ) {
	$rule->{valid} = $ds->valid_vocab;
    }
    
    return $rule;
}


# generate_special_doc ( param )
# 
# Generate the documentation strings for the given special parameter.

sub generate_special_doc {
    
    my ($ds, $param) = @_;
    
    my @doc;
    
    if ( $param eq 'selector' )
    {
	push @doc,
	    "Selects from among the available versions of this data service.",
	    "The value may be one of:";
    }
    
    elsif ( $param eq 'format' )
    {
	push @doc, 
	    "Specifies the output format.  The value may be the name of",
	    "any of the formats available for the selected operation";
    }
    
    elsif ( $param eq 'path' )
    {
	push @doc,
	    "Specifies a data service operation to perform.";
    }
    
    elsif ( $param eq 'document' )
    {
	push @doc,
	     "If a request includes this parameter, then a documentation page is",
	     "returned instead of an operation being executed.";
    }
    
    elsif ( $param eq 'show' )
    {
	push @doc,
	    "Selects additional information to be returned.  The value",
	    "of this parameter must be one or more of the following, separated by commas.";
    }
    
    elsif ( $param eq 'limit' )
    {
	push @doc, 
	    "Limits the number of records returned.",
	    "The value may be a positive integer, zero, or C<all>.";
	
	my $default = $ds->node_attr('', 'default_limit');
	
	if ( defined $default && $default > 0 )
	{
	    push @doc,
		"It defaults to $default, in order to prevent people",
		    "from accidentally sending requests that might generate",
			"extremely large responses.  If you really want the",
			    "entire result set, specify C<limit=all>";
	}
    }
    
    elsif ( $param eq 'offset' )
    {
	push @doc, 
	    "Returned records start at this offset in the result set.",
	    "The value may be a positive integer or zero. You can use",
	    "this parameter along with C<limit> to return a large",
	    "result set in many smaller chunks.";
    }
    
    elsif ( $param eq 'count' )
    {
	push @doc,
	    "If this parameter has a true value, then the response includes",
	    "a header stating the number of records that match the query",
	    "and the number of records actually returned.  To learn how",
	    "this is encoded, see the documentation pages for the various",
	    "output formats.";
    }
    
    elsif ( $param eq 'datainfo' )
    {
	my @extras;
	my $info = $ds->data_info;
	
	push @extras, "=item *", "The name of the data provider"
	    if $info->{data_provider};
	push @extras, "=item *", "The name of the data source"
	    if $info->{data_source};
	push @extras, "=item *", "The license under which it is provided",
	    if $info->{data_license};
	
	push @doc,
	    "If this parameter is has a true value, then the response will",
	    "include header lines with a variety of information including:",
	    "=over",
	    @extras,
	    "=item *", "The date and time at which the data was accessed",
	    "=item *", "The URL and parameters used to generate this result set",
	    "=back",
	    "This is particularly useful for responses that will be saved to",
	    "disk for later analysis and use.  This extra information will",
	    "serve to document the criteria by which data are included in the",
	    "result set and the time at which the result was generated, and",
	    "will contain a URL which can be used to re-run the query at a",
	    "later time.  For more information about how this information is",
	    "encoded, see the documentation pages for the various output formats.";
    }
    
    elsif ( $param eq 'vocab' )
    {
	push @doc,
	    "Selects the vocabulary used to name the fields in the response.",
	    "You only need to use this if you want to override the default",
	    "vocabulary for your selected format.",
	    "Possible values depend upon the particular URL path, and include:",
	    $ds->document_vocabs('/', { valid => 1 });
    }
    
    elsif ( $param eq 'header' )
    {
	push @doc,
	    "This parameter is only relevant for text format responses.  If",
	    "it has a true value, then the data records are preceded by a",
	    "header line giving the field names.  If it has a false value,",
	    "this line will be omitted.  See the documentation pages for",
	    "the various output formats regarding the default behavior if",
	    "this parameter is omitted.";
    }
    
    elsif ( $param eq 'linebreak' )
    {
	push @doc,
	    "Specifies the character sequence used to terminate each line.",
	    "The value may be either 'cr' or 'crlf', and defaults to the",
	    "latter.";
    }
    
    elsif ( $param eq 'save' )
    {
	push @doc,
	    "Specifies the name of a local file to which the output of this",
	    "request should be saved.  Whether and how this happens",
	    "depends upon which web browser you are using.  You can specify",
	    "C<save=no> instead if you wish to display the result in the browser";
	push @doc,
	    "If you include this parameter without any value, a default",
	    "filename will be provided."
		if $ds->node_attr('/', 'default_save_filename');
    }
    
    return @doc;
}


sub ruleset_defined {
    
    my ($ds, $rs_name) = @_;
    
    return $ds->{validator}->ruleset_defined($rs_name);
}


sub list_ruleset_params {
    
    my ($ds, $rs_name) = @_;
    
    return $ds->{validator}->list_params($rs_name);
}


1;
