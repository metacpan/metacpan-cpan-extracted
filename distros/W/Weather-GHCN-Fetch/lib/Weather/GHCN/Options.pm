# Weather::GHCN::Options.pm - class for GHCN options

## no critic (Documentation::RequirePodAtEnd)

=head1 NAME

Weather::GHCN::Options - create and manage option lists/objects used by GHCN modules and scripts

=head1 VERSION

version v0.0.006

=head1 SYNOPSIS

  use Weather::GHCN::Options;


=head1 DESCRIPTION

The B<Weather::GHCN::Options> module provides a class and methods that are
used within GHCN modules or from application scripts that use GHCN
modules to create and manage options that determine the behaviour of
GHCN methods.

The module is primarily for use by module Weather::GHCN::StationTable.

=cut

# these are needed because perlcritic fails to detect that Object::Pad handles these things
## no critic [ValuesAndExpressions::ProhibitVersionStrings]
## no critic [TestingAndDebugging::RequireUseWarnings]

use v5.18;  # minimum for Object::Pad
use warnings;
use Object::Pad 0.66 qw( :experimental(init_expr) );

package Weather::GHCN::Options;
class   Weather::GHCN::Options;

our $VERSION = 'v0.0.006';

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

const my $TRUE   => 1;      # perl's usual TRUE
const my $FALSE  => not $TRUE; # a dual-var consisting of '' and 0
const my $SPACE  => q( );
const my $EMPTY  => q();
const my $DASH   => q(-);
const my $BAR    => q(|);
const my $BANG   => q(!);
const my $NEWLINE => qq(\n);

const my $DEFAULT_PROFILE_FILE  => '~/.ghcn_fetch.yaml';
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

## no critic [ValuesAndExpressions::ProhibitMagicNumbers]
## no critic [ValuesAndExpressions::ProhibitNoisyQuotes]
## no critic [ValuesAndExpressions::ProhibitEmptyQuotes]

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
            [ 'detail level',       'detail' ],
        ]
    ],
    ['', '', '-'],
    ['dataonly',    '!',    undef, label => 'Only print the data table'],
    ['performance', '!',    undef, label => 'Report performance statistics'],
    ['verbose',     '!',    undef, label => 'Print information messages'],

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

    'Profile and Cache',
    ['profile',     '=s',   $DEFAULT_PROFILE_FILE,
                                   label => 'Profile file location (for option preloading)'], #, nogui => 1],
    ['cachedir',    '=s',   undef, label => 'Directory for cached files'],
    ['refresh',    '=s',   'yearly',
        help => 'Refresh yearly, (default), never, always, or if N days old (N > 1)',
        label => 'Cache refresh option',
        choices => [ 'yearly', 'always', 'never', '<N days old>' ],
    ],
];

## use critic [ValuesAndExpressions::ProhibitMagicNumbers]
## use critic [ValuesAndExpressions::ProhibitNoisyQuotes]
## use critic [ValuesAndExpressions::ProhibitEmptyQuotes]

#####################################################################
# Class fields
######################################################################

field $_opt_href     :mutator;   # a hashref of merged options (with default values applied))
field $_opt_obj      :mutator;   # a Hash::Wrap object derived from $_opt_href
field $_profile_href :mutator;   # a hash containing profile file options
field $_tk_opt_aref;             # the Tk:Getopt array that defines all GHCN options

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

=item profile_href

This writable field is set by StationTable->set_options and contains
the profile options it was given.

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
        my $opt_kw_with_aliases = join $BAR, $opt_kw, $alias_aref->@*;

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
            foreach my $slot ( $href->{'choices'}->@* ) {
                if (ref $slot eq 'ARRAY') {
                    $hv{ $slot->[1] } = $slot->[0];
                }
                elsif (ref $slot eq $EMPTY) {
                    $hv{ $slot } = $TRUE;
                }
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

=head2 valid_report_type ($rt, \@opttable)

This function is used to validate the report type.  Valid values are
defined in the built-in Tk options table, which can be obtained by
calling:

    my @opttable = ( Weather::GHCN::Options->get_tk_options_table() );

=cut

method valid_report_type :common ($rt, $opttable_aref) {
    my $choices_href = Weather::GHCN::Options->get_option_choices;
    return $choices_href->{'report'}->{ lc $rt };
}

=head2 deabbrev_report_type ($rt)

The report types supported by the -report option can be abbrevated,
so long as the abbrevation is unambiquous.  For example, 'daily' can
be abbreviated to 'dail', 'dai', or 'da', but not 'd' because 'detail'
is also a valid report type and 'd' would not disambiguate the two.

This function takes a (possibly abbreviated) report type and returns
an unabbreviated report type.

=cut

method deabbrev_report_type :common ($rt) {
        my %r_abbrev = abbrev( qw(detail daily monthly yearly) );
        my $deabbreved = $r_abbrev{ lc $rt };
        return $deabbreved;
}

=head2 valid_refresh_option ($refresh, \@opttable)

This function is used to validate the refresh option.  Valid values are
defined in the built-in Tk options table, which can be obtained by
calling:

    my @opttable = ( Weather::GHCN::Options->get_tk_options_table() );

=cut

method valid_refresh_option :common ($refresh, $opttable_aref) {
    my $choices_href = Weather::GHCN::Options->get_option_choices;
    # we only validate the non-numeric options
    return $TRUE if $refresh =~ m{ \A \d+ \Z }xms;
    return $choices_href->{'refresh'}->{ lc $refresh };
}

=head2 deabbrev_refresh_option ($refresh)

The refresh option values can be abbrevated, so long as the abbrevation
is unambiquous.  For example, 'yearly' can
be abbreviated to 'y', 'ye', 'yea', etc.

This function takes a (possibly abbreviated) refresh option and returns
an unabbreviated refresh option.

=cut

method deabbrev_refresh_option :common ($refresh) {
    # we only deabbreviate the non-numeric options
    return $refresh if $refresh =~ m{ \A \d+ \Z }xms;
    my %r_abbrev = abbrev( qw(yearly never always) );
    my $deabbreved = $r_abbrev{ lc $refresh };
    return $deabbreved;
}


######################################################################
=head1 INSTANCE METHODS

=over 4

=item combine_options ( $user_opt_href, $profile_href={} )

Returns:  ($opt_href, $opt_obj)

This method takes a hash reference containing user options, and optionally
a hash reference of profile options, and combines them with default
values.  The end result is a complete set of all the options
supported by Weather::GHCN::StationTable with user-specified options taking
precedence over profile options, and profile options taking precedence
over defaults.

This set of options is returned as both a hash reference and as a
Hash::Wrap object.  The latter is preferred for use by consuming
applications, because it provides accessor methods for each option.
In addition, an ->defined( "<option>" ) method is provided so that
your code can determine whether an option value was set to B<undef>.

The advantage to using an option object rather than an option hash
is that a misspelled option name will cause a runtime error.

=back

=cut

method combine_options ( $user_opt_href, $profile_href={} ) {
    # assign the class-level tk_options_table aref, generated before BUILD, to the instance field
    $_tk_opt_aref = $Tk_opt_table;

    # start with the user options
    my %merged_options = ( $user_opt_href->%* );

    # merge in the profile options
    while ( my ($k,$v) = each $profile_href->%* ) {
        $merged_options{$k} //= $v;
    }

    my $defaults_href = get_option_defaults();

    # merge in the defaults
    while ( my ($k,$v) = each $defaults_href->%* ) {
        $merged_options{$k} //= $v;
    }

    $_opt_href = \%merged_options;
    $_opt_obj  = _wrap_hash \%merged_options;

    return ($_opt_href, $_opt_obj);
}

=head2 initialize

Returns:  @errors

This method initializes options that can't simply be initialized by
constants.  Specifically:

=over 4

=item Aliases

Alias entries defined in the user profile are matched against
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

    if ( $_opt_obj->country ) {
        # using undef as the search type so it will figure it out based
        # on the value pattern and length
        my @cou = search_country( $_opt_obj->country, undef );

        push @errors, '*E* unrecognized country code or name'
            if not @cou;

        push @errors, '*E* ambiguous country code or name'
            if @cou > 1;

        # return the GEC (FIPS) country code, which is what GHCN uses
        $_opt_obj->country = $cou[0]->{gec};
    }

    # default the station active range to the year filter range if its value is an empty string
    if ( $_opt_obj->defined('active') and $_opt_obj->active eq $EMPTY ) {
        $_opt_obj->active = $_opt_obj->range;
    }

    $_opt_obj->quality = 0
        if $_opt_obj->fmonth or $_opt_obj->fday;

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

    foreach my $k ( sort keys $_opt_href->%* ) {
        next if $k eq 'aliases';
        next if $k eq 'cachedir';
        next if $k eq 'profile';
        my $v = $_opt_href->{$k};
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
the options that were provided to B<set_options> are valid.  It also
handles abbreviations for options color and report.  Any errors
arising from invalid value or from problems detected during
B<intialize> (which is called at the end of B<validate>) are returned
in a list.

=cut

method validate () {
    my @errors;
    my $bad_range_cnt = 0;

    if ( $_opt_obj->defined('aliases') ) {
        foreach my $alias_name ( keys $_opt_obj->aliases->%* ) {
            my $errmsg = '*E* alias names in profile must be lowercase letters with optional underscore prefix: ' . $alias_name;
            push @errors, $errmsg
                unless $alias_name =~ $ALIAS_NAME_RE;
        }
    }

    if ( $_opt_obj->active ) {
        if ( not $_opt_obj->active =~ m{ \A (18|19|20)\d\d [-] (18|19|20)\d\d }xms ) {
            push @errors, '*E* invalid -active year range ' . $_opt_obj->active;
            $bad_range_cnt++;
        }
    }

    if ( $_opt_obj->range ) {
        if ( not $_opt_obj->range =~ m{ \A (18|19|20)\d\d [-,] (18|19|20)\d\d }xms ) {
            push @errors, '*E* invalid -range ' . $_opt_obj->range;
            $bad_range_cnt++;
        }
    }

    push @errors, '*E* invalid 2-character state or province code ' . $_opt_obj->state
        if $_opt_obj->defined('state') and not $_opt_obj->state =~ m{ \A [[:alpha:]]{2} \Z }xms;

    push @errors, '*E* -partial only allowed if -active specified'
        if $_opt_obj->partial and not $_opt_obj->defined('active');

    # Note: full Condition Coverage in Devel::Cover seems impossible if these two ifs are combined
    #       (I tried every combination of uncoverable branch and condition I could think of to
    #        to suppress the missing case.  In the end, this was the only thing that worked.)
    if ( $_opt_obj->range and $_opt_obj->active ) {
        # uncoverable branch false
        if ( $bad_range_cnt == 0 ) {
            my $r = rng_new( $_opt_obj->range  );
            my $a = rng_new( $_opt_obj->active );

            push @errors, '*E* -range must be a subset of -active'
                if not $r->subset($a);
        }
    }

    push @errors, '*E* -gps argument must be decimal lat/long, separated by spaces or punctuation'
        if $_opt_obj->gps and $_opt_obj->gps !~ m{ \A [+-]? \d{1,3} [.] \d+ (?: [[:punct:]] | \s+ ) [+-]? \d{1,3} [.] \d+ \Z }xms;

    #-----------------------------------------------------------------
    # Maintenance Note
    #-----------------------------------------------------------------
    #
    # GHCN::Fetch uses Tk::Getopt rather than Getopt::Long and as
    # a result it does it's own validation checking of -report and
    # -refresh before the validate() method of this module gets called.
    # Unfortunately, the error message is useless because it fails to
    # print out the choices correctly.  So, special code was written
    # in GHCN::Fetch to allow the -report and -refresh options to be
    # abbreviated, and to validate them, and to issue proper error
    # messages when they are invalid.
    #
    # Consequently, by the time this code is reached, any abbreviation
    # to $_opt_obj->report (or $_opt_obj->refresh) has already been replaced,
    # and validation and error reporting has been done done.

    my %report_abbrev = abbrev( qw(detail daily monthly yearly) );

    my $report = lc $_opt_obj->report;

    # uncoverable branch true
    croak '*E* undef report type'
        if not defined $report;

    push @errors, '*E* invalid report option: ' . $report
        if $report and not $report_abbrev{ $report };

    $_opt_obj->report = $report_abbrev{ $report };


    my %refresh_abbrev = abbrev( qw(yearly never always) );

    my $refresh = lc $_opt_obj->refresh;

    # uncoverable branch true
    croak '*E* undef refresh option'
        if not defined $refresh;

    push @errors, '*E* invalid refresh option: ' . $refresh
        if $refresh and not $refresh_abbrev{ $refresh };

    $_opt_obj->refresh = $refresh_abbrev{ $refresh };

    #-----------------------------------------------------------------
    # end of noted section
    #-----------------------------------------------------------------

    my %color_abbrev = abbrev( qw(blue green azure purple red white yellow) );

    # uncoverable branch false
    if ( $_opt_obj->defined('color') ) {
        my $color = $_opt_obj->color;
        if ( $color eq $EMPTY ) {
            push @errors, '*E* invalid -color value ""'
        } else {
            push @errors, '*E* invalid -color value'
                if not $color_abbrev{ $color };
        }
        $_opt_obj->color = $color_abbrev{ $color };
    }


    push @errors, '*E* -label/-nolabel only allowed if -kml specified'
        if $_opt_obj->defined('label') and not $_opt_obj->defined('kml');

    if ( $_opt_obj->defined('fmonth') ) {
        push @errors, '*E* -fmonth must be a single number or valid range spec (e.g. 1-5,9)'
            if not rng_valid($_opt_obj->fmonth)
            or not rng_within($_opt_obj->fmonth, '1-12');
    }

    if ( $_opt_obj->defined('fday') ) {
        push @errors, '*E* -fday must be a single number or valid range spec (e.g. 3,15,20-31)'
            if not rng_valid($_opt_obj->fday)
            or not rng_within($_opt_obj->fday, '1-31');
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

sub _get_boolean_options ($_tk_opt_aref) {

    my %boolean;

    foreach my $row ( $_tk_opt_aref->@* ) {
        next unless ref $row eq 'ARRAY';
        my ($name, $type) = $row->@*;
        $boolean{$name}++ if $type eq $BANG;
    }

    return \%boolean;
}

1;
