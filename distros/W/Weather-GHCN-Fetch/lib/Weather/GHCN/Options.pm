# Weather::GHCN::Options.pm - class for GHCN options

## no critic (Documentation::RequirePodAtEnd)

=head1 NAME

Weather::GHCN::Options - create and manage option lists/objects used by GHCN modules and scripts

=head1 VERSION

version v0.0.003

=head1 SYNOPSIS

  use Weather::GHCN::Options;


=head1 DESCRIPTION

The B<Weather::GHCN::Options> module provides a class and methods that are
used within GHCN modules or from application scripts that use GHCN
modules to create and manage options that determine the behaviour of
GHCN methods.

The module is primarily for use by module Weather::GHCN::StationTable.

=cut

use v5.18;  # minimum for Object::Pad
use Object::Pad 0.66 qw( :experimental(init_expr) );

package Weather::GHCN::Options;
class   Weather::GHCN::Options;

our $VERSION = 'v0.0.003';

use Carp                qw(carp croak);
use Const::Fast;
use Hash::Wrap          {-lvalue => 1, -defined => 1, -as => '_wrap_hash'};
use Text::Abbrev;
use Weather::GHCN::CountryCodes  qw( search_country );
use Weather::GHCN::Common        qw( :all );
use YAML::Tiny;

######################################################################
# Constants
######################################################################

const my $SPACE => q( );
const my $EMPTY => q();
const my $DASH  => q(-);
const my $NEWLINE => qq(\n);

const my $ALIAS_NAME_RE => qr{ \A [_]?[[:lower:]]+ \Z }xms;

=head1 METHODS

=head2 new

Create a new Options object.

=cut

######################################################################
# Set up the default Tk::Getopt option table, which we will use for
# both Tk::Getopt and to derive an options list of Getopt::Long
# for when Tk::Getopt is not installed.
######################################################################

my $Tk_opt_table = [
    'Basic options',
    ['location',     '=s',   undef, label => 'Filter stations by their location name (regex)'],
    ['state',        '=s',   undef, label => 'Filter stations by state or province',
                                    alias => ['province'] ],
    ['country',      '=s',   undef, label => 'Filter station by the country they are in'],
    ['gsn',          '!',    undef, label => 'Include only GSN reference stations'],
    ['', '', '-'],
    ['report',       '=s',   '',
        label => 'Type of report',
        strict => 1,
        choices => [
            [ 'station list',       '' ],
            [ 'yearly summary',     'yearly' ],
            [ 'monthly summary',    'monthly' ],
            [ 'daily summary',      'daily' ],
            [ 'station (id) level', 'id' ],
        ]
    ],
    ['', '', '-'],
    ['nonetwork',    '=i',   -1,
        help => 'Set the NoNetwork option in URI::Fetch',
        label => 'Cache refresh option',
        choices => [
            ['Refresh if stale this year', -1 ],    ## no critic [ProhibitMagicNumbers]
            ['Check for fresher copy',      0 ],
            [q(Don't refresh cache),        1 ],
        ],
    ],
    ['performance', '!',    undef, label => 'Report performance statistics'],
    ['verbose',     '!',    undef, label => 'Print information messages'],
    ['dataonly',    '!',    undef, label => 'Only print the data table'],
    ['config',      '=s',   undef, label => 'Configuration options (for testing only)', nogui => 1],

    'Date filters',
    ['range',       '=s',   undef, label => 'Filter selected station data by year range'],
    ['active',      '=s',   undef, label => 'Filter stations by their active year range'],
    ['partial',     '!',    undef, label => 'Allow stations only active for part of the active range'],
    ['quality',     '=i',   90,    label => 'Quality threshold (percent as an integer)'],
    ['', '','-'],
    ['fday',        '=s',   undef, label => 'Filter output to include a specific day'],
    ['fmonth',      '=s',   undef, label => 'Filter output to include a specific month'],

    'GIS filters',
    ['gps',         '=s',   undef, label => 'Filter stations by latitude and longitude',
                                   help  => 'Enter decimal latitude and longitude'],
    ['radius',      '=i',   50,    label => 'Radius to search for stations near coordinates'],


    'Analysis Options',
    ['anomalies',   '!',    undef, label => 'Provide calculated anomalies in the output'],
    ['baseline',    '=s',   '1971-2000',
                                   label => 'Baseline year range'],
    ['precip',      '!',    undef, label => 'Include precipitation stats in the results'],
    ['tavg',        '!',    undef, label => 'Include TAVG in the results'],
    ['nogaps',      '!',    undef, label => 'Emit extra rows for missing months or days'],

    'KML Output',
    ['kml',         '=s',   undef, label => 'Export station coordinates to a KML file'],
    ['color',       '=s',   'red', label => 'Color to use for KML placemarks',
                                   alias => ['colour'] ],
    ['label',       '!',    undef, label => 'Label KML placemarks'],
];

    ######################################################################
# Class fields
######################################################################

field $opt_href     :mutator;   # a hashref of merged options (with default values applied))
field $opt_obj      :mutator;   # a Hash::Wrap object derived from $opt_href
field $config_href  :mutator;   # a hash containing config file options
field $tk_opt_aref;             # the Tk:Getopt array that defines all GHCN options

=head1 FIELD ACCESSORS

Writeable (mutator) access is provided for some fields primarily so
an Options object can be tested independantly from StationTable.
In general, an Options object is set by the StationTable set_options
method and should not be modified directly by the consuming application
using these mutators.

=over 4

=item opt_href

This writable field is set by StationTable->set_options and is a
hashref of user options merged with default values.

For programmatic access to option values, use of B<opt_obj> is
preferred to prevent mispellings.  (See B<opt_obj>.)

=item opt_obj

This writable field is set by StationTable->set_options and is a
Hash::Wrap object composed from the B<opt_href> hashref field.  It
provides accessor field methods for user options (merged with default
values).

Using this object, rather than B<opt_href>, for access to option
values is safer programming choice as any misspelling of an option
name will result in a run time error.  In contrast, mispelling a hash
key will simply result in an undef being returned.

=item config_href

This writable field is set by StationTable->set_options and contains
the configuration options it was given.

=back

=cut

######################################################################
=head1 CLASS METHODS

The following class methods are supported.  Class Options uses
Object::Perl, so these class methods (specified using the :common
method attribute) should be accessed using -> not :: because ->
will shift off the $class argument and :: won't.

=head2 get_tk_options_table

Returns:  @tk_opttable or \@tk_opttable

Provides access to the predefined TK::Getopt options list that define
the Getopt::Long arguments supported by class StationTable for user
options.

The table is a list of lists and strings.  The strings define
sections that Tk::Getopt renders as panels or tabs in the GUI it
constructs. The lists contain option names and types (in Getopt::Long
style) as well as default values, aliases, and labels to be displayed
in the GUI, choices for multi-select options, and other extensions.
See Tk::Getopt OPTTABLE ARGUMENTS for details.

=cut

method get_tk_options_table :common () {
    return wantarray ? ( $Tk_opt_table->@* ) : $Tk_opt_table;
}

=head2 get_getopt_list

Returns:  @options or \@options

In scalar context, return a list reference to a translation of the
TK::Getopt options list into the simpler list used by Getopt::Long.
This gives application authors a choice between using Tk::Getopt and
the non-GUI and more traditional Getopt::Long.

In list context, this method returns a Getopt::Long-style list
options.

Typically, this method would be called prior to Getopt::Long in order
to obtain an options list for using the StationTable class; e.g.

    my %opt;
    my @options = ( Weather::GHCN::Options->get_getopt_list() );
    GetOptions( \%opt, @options);

=cut

method get_getopt_list :common () {
    ## no critic [ProhibitDoubleSigils]
    my @options_text;
    my @options_list;
    my @options;

    # According to https://metacpan.org/pod/Tk::Getopt -opttable 
    # should be a reference to an array containing all options. 
    # Elements of this array may be strings, which indicate the 
    # beginning of a new group, or array references describing the 
    # options. The first element of this array is the name of the 
    # option, the second is the type (=s for string, =i for integer, 
    # ! for boolean, =f for float etc., see Getopt::Long) for a 
    # detailed list. The third element is optional and contains the 
    # default value (otherwise the default is undefined). 
    # Further elements are optional too and describe more attributes. For a 
    # complete list of these attributes refer to "OPTTABLE ARGUMENTS".

    foreach my $row ( $Tk_opt_table->@* ) {
        next if ref $row ne 'ARRAY';

        # pick off the first three values, then slurp the rest
        my ($opt_kw, $opt_type, $default, @others) = $row->@*;
        # skip the group dividers
        next if not $opt_kw;
        
        # now figure out whether the slurped values are a hash of
        # other options (including label) or just a pair of scalars 
        # ('label' and label value with no other options).
        my %h;
        if (@others > 1 && ref $others[0] eq 'HASH') {
            %h = @others;
        }
        elsif (@others > 1 && $others[0] eq 'label') {
            $h{'label'} = $others[2];
        }

        my $label = $h{'label'} // $SPACE;
        my $alias_aref = $h{'alias'} // [];
        my $opt_kw_with_aliases = join '|', $opt_kw, $alias_aref->@*;

        push @options_list, $opt_kw_with_aliases . $opt_type;
        push @options, [$opt_kw_with_aliases, $opt_type, $label];
    }

    # calculate the width of the option spec column so the labels,
    # which we print as comment in the text output, will line up

    my $colwidth = 0;
    foreach my $opt_aref (@options) {
        my ($opt_kw_with_aliases, $opt_type, $label) = $opt_aref->@*;
        my $len = length( q(') . $opt_kw_with_aliases . $opt_type . q(', ) );
        $colwidth = $len if $len > $colwidth;
    }

    my $fmt = sprintf '%%-%ds', $colwidth;

    foreach my $opt_aref (@options) {
        my ($opt_kw_with_aliases, $opt_type, $label) = $opt_aref->@*;
        my $kw = sprintf $fmt, q(') . $opt_kw_with_aliases . $opt_type . q(',);
        push @options_text, $kw . '# ' . $label;
    }

    return wantarray ? ( @options_list ) : join $NEWLINE, sort @options_text;
}


=head2 get_option_choices ( $option )

Returns:  \%choices

Find all the options which have a multiple choice response, and return 
a hash keyed on the option name and with a values consisting
of a hash of the valid responses as value/label pairs.

=cut

method get_option_choices :common () {
    my %choices;

    foreach my $row ( $Tk_opt_table->@* ) {
        next if ref $row ne 'ARRAY';

        # pick off the first three values, then slurp the rest
        my ($opt_kw, $opt_type, $default, @others) = $row->@*;
        # skip the group dividers
        next if not $opt_kw;
        
        my $href;
        if (@others and ref $others[0] eq 'HASH' ) {
            $href = $others[0];
        } elsif (@others % 2 == 0) {
            $href = { @others };
        } else {
            croak "*E* unable to parse opttable: @others";
        }

        my %hv;
        if ( $href->{'choices'} and ref $href->{'choices'} eq 'ARRAY' ) {
            foreach my $aref ( $href->{'choices'}->@* ) {
                $hv{ $aref->[1] } = $aref->[0];
            }
            $choices{$opt_kw} = \%hv;            
        }
    }

    return \%choices;
}

=head2 get_option_defaults

Returns:  \%defaults

Returns the option defaults, obtained from the same predefined list
of lists/strings returned by get_tk_options_table.

=cut

method get_option_defaults :common () {

    my %defaults = ();
    foreach my $slot ($Tk_opt_table->@*) {
        next if ref $slot ne 'ARRAY';
        my $key = $slot->[0];
        next if not $key;
        my $default_value = $slot->[2];
        $defaults{$key} = $default_value;
    }

    return \%defaults;
}


######################################################################
=head1 INSTANCE METHODS

=over 4

=item combine_options ($user_opt_href)

Returns:  ($opt_href, $opt_obj)

This method takes a hash reference containing user options, merges it
with the full set of supported options, and applies any necessary
default values.  The end result is a complete set of all the options
supported by Weather::GHCN::StationTable with user-specified options taking
precedence over all other.

This set of options is returned as both a hash reference and as a
Hash::Wrap object.  The latter is preferred for use by consuming
applications, because it provides accessor methods for each option.
In addition, an ->defined( "<option>" ) method is provided so that
your code can determine whether an option value was set to B<undef>.

The advantage to using an option object rather than an option hash
is that a misspelled option name will cause a runtime error.

=back

=cut

method combine_options ($user_opt_href) {
    # assign the class-level tk_options_table aref, generated before BUILD, to the instance field
    $tk_opt_aref = $Tk_opt_table;

    my $defaults_href = get_option_defaults();

    my %merged_options;
    while ( my ($k,$v) = each $defaults_href->%* ) {
        $merged_options{$k} = $user_opt_href->{$k} // $v;
    }

    $opt_href = \%merged_options;
    $opt_obj  = _wrap_hash \%merged_options;

    return ($opt_href, $opt_obj);
}

=head2 initialize

Returns:  @errors

This method initialize various user and configuration options that
can't simply be initialized by constants.  Specifically:

=over 4

=item Aliases

Alias entries defined in configuration options are matched against
the -location option value.  If a match is found to the alias name,
the alias value is substituted for the location value.

Alias names must be lowercase letters only.  An optional underscore
prefix is permitted.  Names not matching this rule will be silently
ignored by initialize().

=item country

The B<country> option value can be:

    * a 2-character GEC (FIPS) country code

    * a 3-character alpha ISO 3166 country code

    * a 3-digit numeric ISO 3166 country number

    * an internet domain country suffix (e.g. '.ca')

    * a 3-character regex string

If a regex string is given, then it will be matched (unanchored and
case insensitve) against country names.  If multiple matches are
found, then an error is returned and the user will need to provide a
more specific pattern.

=item active

The B<active> option filters stations according to the years that
they were active.  If the B<range> option is specified, but the
B<active> option is not, then B<initialize> will set the B<active>
option value to the B<range> option value so that only stations that
were active during the requested data range will be selected.

=item quality

The B<quality> option determines whether a station's data will be
included in the output when it has missing data.  Quality is
expressed as a number between 0 and 100, representing the percentage
of data that cannot be missing; 90% is the default  For example, if
you have a range of 3 years (1095 days) when B<quality> is 90, then
you need 90% x 1095 = 985 days of data.  Anything less and the
station is rejected.

When filters fmonth and fday are used, the amount of data included
will typically drop far below 90% thereby rejecting all stations.
To avoid this nuisance, B<initialize> will set quality to 0% if
either the B<fmonth> or B<fday> options are present.

=back

=cut

method initialize () {
    my @errors;

    # substitute any aliases found in -location string into their station id's
    if ( $opt_obj->location and $config_href->{'aliases'} ) {
        if ( $opt_obj->location =~ m{ \A [_]?[[:lower:]]+ \Z }xms ) {
            while ( my ($k,$v) = each $config_href->{'aliases'}->%* ) {
                $opt_obj->location =~ s{$k}{$v}xms;
            }
        }
    }

    if ( $opt_obj->country ) {
        # using undef as the search type so it will figure it out based
        # on the value pattern and length
        my @cou = search_country( $opt_obj->country, undef );

        push @errors, '*E* unrecognized country code or name'
            if not @cou;

        push @errors, '*E* ambiguous country code or name'
            if @cou > 1;

        # return the GEC (FIPS) country code, which is what GHCN uses
        $opt_obj->country = $cou[0]->{gec};
    }

    # default the station active range to the year filter range if its value is an empty string
    if ( $opt_obj->defined('active') and $opt_obj->active eq $EMPTY ) {
        $opt_obj->active = $opt_obj->range;
    }

    $opt_obj->quality = 0
        if $opt_obj->fmonth or $opt_obj->fday;

    return @errors;
}

=head2 options_as_string

This option returns a string that contains all the options and their
values, in a format similar to what they would look like when entered
as command-line arguments.  For boolean options only the option name
is include (no value).  Option values containing whitespace are
enclosed in double quotes.  Option/value pairs are separated by
two spaces.

This method is primarily provided so the consuming application can
print the options that were used during a run, perhaps to a log or
in the output.

=cut

method options_as_string () {
    my @options;
    my $boolean = _get_boolean_options($Tk_opt_table);

    foreach my $k ( sort keys $opt_href->%* ) {
        my $v = $opt_href->{$k};
        next if not defined $v;

        if ( $boolean->{$k} ) {
            push @options, $DASH . $k;
            next;
        }

        my $val = $v;

        if ( $val =~ m{\A \s* \Z}xms ) {
            $val = q(") . $val . q(");
        }
        push @options, $DASH . $k. $SPACE . $val;
    }
    return join $SPACE x 2, @options;
}

=head2 validate

Returns:  @errors

This method is called by StationTable->set_options to make sure all
the options and configuration values that were provided to
B<set_options> are valid.  It also handles abbreviations for options
color and report.  Any errors arising from invalid value or from
problems detected during B<intialize> (which is called at the end of
B<validate>) are retuned in a list.

=cut

method validate () {
    my @errors;
    my $bad_range_cnt = 0;

    if ( $config_href->{aliases} ) {
        foreach my $alias_name ( keys $config_href->{aliases}->%* ) {
            my $errmsg = '*E* alias names in configuration must be lowercase letters with optional underscore prefix: ' . $alias_name;
            push @errors, $errmsg
                unless $alias_name =~ $ALIAS_NAME_RE;
        }
    }

    if ( $opt_obj->active ) {
        if ( not $opt_obj->active =~ m{ \A (18|19|20)\d\d [-] (18|19|20)\d\d }xms ) {
            push @errors, '*E* invalid -active year range ' . $opt_obj->active;
            $bad_range_cnt++;
        }
    }

    if ( $opt_obj->range ) {
        if ( not $opt_obj->range =~ m{ \A (18|19|20)\d\d [-,] (18|19|20)\d\d }xms ) {
            push @errors, '*E* invalid -range ' . $opt_obj->range;
            $bad_range_cnt++;
        }
    }

    push @errors, '*E* invalid 2-character state or province code ' . $opt_obj->state
        if $opt_obj->defined('state') and not $opt_obj->state =~ m{ \A [[:alpha:]]{2} \Z }xms;

    push @errors, '*E* -partial only allowed if -active specified'
        if $opt_obj->partial and not $opt_obj->defined('active');

    # Note: full Condition Coverage in Devel::Cover seems impossible if these two ifs are combined
    #       (I tried every combination of uncoverable branch and condition I could think of to
    #        to suppress the missing case.  In the end, this was the only thing that worked.)
    if ( $opt_obj->range and $opt_obj->active ) {
        # uncoverable branch false
        if ( $bad_range_cnt == 0 ) {
            my $r = rng_new( $opt_obj->range  );
            my $a = rng_new( $opt_obj->active );

            push @errors, '*E* -range must be a subset of -active'
                if not $r->subset($a);
        }
    }

    push @errors, '*E* -gps argument must be decimal lat/long, separated by spaces or punctuation'
        if $opt_obj->gps and $opt_obj->gps !~ m{ \A [+-]? \d{1,3} [.] \d+ ( [[:punct:]] | \s+ ) [+-]? \d{1,3} [.] \d+ \Z }xms;

    #-----------------------------------------------------------------
    # Maintenance Note
    #-----------------------------------------------------------------
    #
    # ghcn_fetch.pl uses Tk::Getopt rather than Getopt::Long and as
    # a result it does it's own validation checking of -report before
    # the validate() method of this module gets called.  Unfortunately,
    # the error message is useless because it fails to print out the
    # choices correctly.  So, special code was written in ghcn_fetch
    # to allow the -report option to be abbreviated, and to validate
    # it, and to issue a proper error message when it's invalid.
    #
    # Consequently, by the time this code is reached, any abbreviation
    # to $opt_obj->report has already be replaced, and validation
    # and error reporting done.

    my %report_abbrev = abbrev( qw(id daily monthly yearly) );

    my $report = $opt_obj->report;

    # uncoverable branch true
    croak "*E* undef report type"
        if not defined $report;

    push @errors, '*E* invalid report option: ' . $report
        if $report and not $report_abbrev{ $report };

    $opt_obj->report = $report_abbrev{ $report };

    #-----------------------------------------------------------------
    # end of noted section
    #-----------------------------------------------------------------

    my %color_abbrev = abbrev( qw(blue green azure purple red white yellow) );

    # uncoverable branch false
    if ( $opt_obj->defined('color') ) {
        my $color = $opt_obj->color;
        if ( $color eq $EMPTY ) {
            push @errors, '*E* invalid -color value ""'
        } else {
            push @errors, '*E* invalid -color value'
                if not $color_abbrev{ $color };
        }
        $opt_obj->color = $color_abbrev{ $color };
    }


    push @errors, '*E* -label/-nolabel only allowed if -kml specified'
        if $opt_obj->defined('label') and not $opt_obj->defined('kml');

    if ( $opt_obj->defined('fmonth') ) {
        push @errors, '*E* -fmonth must be a single number or valid range spec (e.g. 1-5,9)'
            if not rng_valid($opt_obj->fmonth)
            or not rng_within($opt_obj->fmonth, '1-12');
    }

    if ( $opt_obj->defined('fday') ) {
        push @errors, '*E* -fday must be a single number or valid range spec (e.g. 3,15,20-31)'
            if not rng_valid($opt_obj->fday)
            or not rng_within($opt_obj->fday, '1-31');
    }

    my @init_errors = $self->initialize();

    return (@errors, @init_errors);
}

=head2 DOES

Defined by Object::Pad.  Included for POD::Coverage.

=head2 META

Defined by Object::Pad.  Included for POD::Coverage.

=cut

######################################################################
# Subroutines
######################################################################

sub _get_boolean_options ($tk_opt_aref) {

    my %boolean;

    foreach my $row ( $tk_opt_aref->@* ) {
        next unless ref $row eq 'ARRAY';
        my ($name, $type) = $row->@*;
        $boolean{$name}++ if $type eq '!';
    }

    return \%boolean;
}


1;
