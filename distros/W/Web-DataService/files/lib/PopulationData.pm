# 
# PopulationData.pm
# 
# This module is used by the example data service application that comes with
# Web::DataService.  It provides the "primary role" for all of the data
# service requests supported by that application.  
# 
# You can use this as a base for your own data service application.
# 
# AUTHOR:
# 
#   mmcclenn@cpan.org



use strict;

package PopulationData;

use HTTP::Validate qw(:validators);
use Carp qw(carp croak);

use Moo::Role;


my ($data, $states);

# The following 'initialize' method is called automatically at application
# startup.  It is passed a reference to the Web::DataService object, which can
# then be used to read data, define output blocks, define rulesets, etc.  If
# you are using a backend database, and if the relevant information has been
# added to the file config.yml, you can call the get_connection method if
# necessary to obtain a handle by which you can make queries.

# You can define the necessary output blocks and rulesets either here or in
# the main application file, or in a separate file, depending upon how you
# wish to structure your code.  The author finds it best to put them here,
# together with the methods for carrying out the various data service
# operations.

sub initialize {

    my ($class, $ds) = @_;
    
    # First read in the data that we will be serving, and put it in the data
    # service scratchpad for use by the various data service operations.  A
    # more complex data service application might instead set up a database
    # connection and read from it as necessary to satisfy each operation.
    
    my $datafile = $ds->config_value('data_file');
    croak "no data file was specified: add the configuration directive 'data_file' to the file 'config.yml'.\n"
	unless defined $datafile && $datafile ne '';
    
    $class->read_data($datafile, \$data, \$states);
    
    # Next we define some output blocks, each of which specifies one or more
    # fields to be displayed as part of the output.
    
    $ds->define_block( 'basic' =>
	{ output => 'name' },
	    "The name of the state",
	{ output => 'abbrev' },
	    "The standard abbreviation for the state",
	{ output => 'region' },
	    "The region of the country in which the state is located",
	{ output => 'pop2010' },
	    "The population of the state in 2010");
    
    $ds->define_block( 'history' =>
	{ output => 'pop2000' },
	    "The population of the state in 2000",
	{ output => 'pop1990' },
	    "The population of the state in 1990",
	{ output => 'pop1950' },
	    "The population of the state in 1950",
	{ output => 'pop1900' },
	    "The population of the state in 1900",
	{ output => 'pop1790' },
	    "The population of the state in 1790");
    
    $ds->define_block( 'total' =>
	{ select => 'totals' });
    
    $ds->define_block( 'regions' =>
	{ output => 'value', name => 'code' },
	    "Region code",
	{ output => 'doc_string', name => 'description' },
	    "Region description");
    
    # This map selects additional optional information that can be selected
    # with the 'show' parameter.
    
    $ds->define_output_map( 'extra' =>
	{ value => 'hist', maps_to => 'history' },
	    "Include historical population information",
	{ value => 'total', maps_to => 'total' },
	    "Add a record for the total population of the selected state(s)");
    
    # The following map specifies the region codes that can be used for selecting
    # states. 
    
    $ds->define_set( 'regions' =>
	{ value => 'NE' },
	    "New England",
	{ value => 'MA' },
	    "Mid Atlantic",
	{ value => 'SE' },
	    "South East",
	{ value => 'MW' },
	    "Mid West",
	{ value => 'WE' },
	    "West");
    
    # The following map specifies the options for output ordering.
    
    $ds->define_set( 'output_order' =>
	{ value => 'name' },
	    "Order the output records alphabetically by name",
	{ value => 'name.desc' },
	    "Order the output records reverse alphabetically by name",
	{ value => 'pop' },
	    "Order the output records by current population, least to most",
	{ value => 'pop.desc' },
	    "Order the output records by current population, most to least");
    
    # Create a validator for state names.
    
    my $valid_state = sub {
	my ($value) = @_;
	return { error => "the value of {param} must be a valid state name or abbreviation" }
	    unless $states->{uc $value};
    };
    
    # The following rulesets are used to validate the parameters for these operations.
    
    $ds->define_ruleset( 'special' =>
	{ ignore => 'doc' },
	{ optional => 'SPECIAL(all)' });
    
    $ds->define_ruleset( 'single' =>
        "The following parameter is required for this operation:",
	{ param => 'state', valid => $valid_state, clean => 'uc' },
	    "Return information about the specified state.",
	    "You may specify either the full name or standard abbreviation.",
        "You may also use the following parameter if you wish:",
	{ optional => 'SPECIAL(show)', valid => 'extra' },
	    "Display additional information about the specified state.  The value",
	    "of this parameter must be one or more of the following, separated by commas.",
	{ allow => 'special' },
	"^You can also use any of the L<special parameters|node:special> with this request.");
    
    $ds->define_ruleset( 'list' =>
	"You can use any of the following parameters with this operation:",
	{ optional => 'state', valid => $valid_state, list => qr{,}, clean => 'uc' },
	    "Return information about the specified state or states.",
	    "You may specify either the full names or standard abbreviations,",
	    "and you may specify more than one separated by commas.",
	{ optional => 'region', valid => 'regions', list => qr{,}, clean => 'uc' },
	    "Return information about all of the states in the specified region(s).",
	    "The regions are as follows:",
	{ optional => 'order', valid => 'output_order' },
	    "Specify how the output records should be ordered:",
	{ optional => 'SPECIAL(show)', valid => 'extra' },
	    "Display additional information about the selected states.  The value",
	    "of this parameter must be one or more of the following, separated by commas.",
	{ allow => 'special' },
	"^You can also use any of the L<special parameters|node:special> with this request.");
    
    $ds->define_ruleset( 'regions' =>
	{ allow => 'special' },
	"^You can use any of the L<special parameters|node:special> with this request.");
}


# read_data ( filename, data_ref, states_ref )
# 
# Reads the specified data file, and returns two data handles.  The first will
# be a list of records, and the second a hash of state names.

sub read_data {

    my ($class, $filename, $data_ref, $states_ref) = @_;
    
    my @records;
    my %names;
    my $past_header;
    
    open( my $infile, "<", $filename ) || die "could not open data file '$filename': $!";
    
 LINE:
    while ( <$infile> )
    {
	next LINE unless $past_header++;
	
	s/\s+$//;
	my @values = split /\t/;
	
	$names{uc $values[0]} = 1;
	$names{uc $values[1]} = 1;
	
	push @records, { name => $values[0],
			 name_uc => uc $values[0],
			 abbrev => $values[1],
			 region => $values[2],
			 pop2010 => $values[3],
			 pop2000 => $values[4],
			 pop1990 => $values[5],
			 pop1950 => $values[6],
			 pop1900 => $values[7],
			 pop1790 => $values[8] };
    }
    
    $$data_ref = \@records;
    $$states_ref = \%names;
}


# The following methods are associated with data service operations by the
# calls to 'define_path' in the main application file.
# =========================================================================

# Return information about a single state.

sub single {

    my ($request) = @_;
    
    # Get the relevant request parameters.
    
    my $name = $request->clean_param('state');
    
    # Locate the matching record, if any, and return it.
    
    foreach my $record ( @$data )
    {
	next unless $record->{name_uc} eq $name || $record->{abbrev} eq $name;
	return $request->single_result($record);
    }
}


# Return information about multiple states.

sub list {

    my ($request) = @_;
    
    # Get the relevant request parameters.
    
    my $name_filter = $request->clean_param_hash('state');
    my $region_filter = $request->clean_param_hash('region');
    my $order = $request->clean_param('order');
    my $totals = $request->has_block('total');
    
    my $return_all; $return_all = 1 unless $request->param_given('state') ||
	$request->param_given('region');
    
    # Filter for matching records.
    
    my @result;
    my $total; $total = { name => "Total" } if $totals;
    
    foreach my $record ( @$data )
    {
	if ( $return_all ||
	     ($name_filter->{$record->{name_uc}}) ||
	     ($name_filter->{$record->{abbrev}}) ||
	     ($region_filter->{$record->{region}}) )
	{
	    push @result, $record;
	    
	    if ( $totals )
	    {
		foreach my $field ( qw( pop1790 pop1900 pop1950 pop1990 pop2000 pop2010 ) )
		{
		    $total->{$field} += $record->{$field} if $record->{$field};
		}
	    }
	}
    }
    
    # Now sort them if we were so requested.
    
    if ( $order eq 'pop' )
    {
	@result = sort { $a->{pop2010} <=> $b->{pop2010} } @result;
    }
    
    elsif ( $order eq 'pop.desc' )
    {
	@result = sort { $b->{pop2010} <=> $a->{pop2010} } @result;
    }
    
    elsif ( $order eq 'name' )
    {
	@result = sort { $a->{name_uc} cmp $b->{name_uc} } @result;
    }
    
    elsif ( $order eq 'name.desc' )
    {
	@result = sort { $b->{name_uc} cmp $a->{name_uc} } @result;
    }
    
    # Add the total record if one was requested;
    
    push @result, $total if $totals;
    
    # Now return the result set.
    
    $request->list_result(\@result);
}


# Return the list of region codes.

sub regions {
    
    my ($request) = @_;
    
    my $ds = $request->ds;
    $request->list_result($ds->set_values('regions'));
}

1;
