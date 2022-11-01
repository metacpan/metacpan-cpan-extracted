# Weather::GHCN::Fetch.pm - class for creating applications that fetch NOAA GHCN data

## no critic (Documentation::RequirePodAtEnd)

=head1 NAME

Weather::GHCN::App::Fetch - Fetch station and weather data from the NOAA GHCN repository

=head1 VERSION

version v0.0.009

=head1 SYNOPSIS

    use Weather::GHCN::App::Fetch;

    Weather::GHCN::App::Fetch->run( \@ARGV );

See ghcn_fetch -help for details.

=cut

# Testing notes:
#
# The quickest way to spot check results from this script is to compare them
# to those obtained from:
#
#   https://ottawa.weatherstats.ca/charts/
#
# Run the script with parameters such as -prov ON -loc "Ottawa Int" -range
# 2017-2018 -precip -tavg -o first with the -daily option, then again with
# -monthly and -yearly. You can then compare results to various charts you
# generate using the above link by selecting Ottawa (Kanata - Orleans),
# which I've verified corresponds to station CA006105976 (Ottawa Int'l).
#
# Charts to use include Temperature (TMAX, TMIN, TAVG, Avg), Snowfall
# (SNOW), Snow on Ground (SNWD) and Total Precipitation (PRCP). Annual and
# monthly charts work well, but you may need daily charts and some
# investigation of the NOAA source data if there are anomalies. Sometimes
# the NOAA data has missing data; e.g. station CA006105976 (Ottawa Int'l)
# is missing days 6-28 for 2018-02.

########################################################################
# Pragmas
########################################################################

# these are needed because perlcritic fails to detect that Object::Pad handles these things
## no critic [ProhibitVersionStrings]
## no critic [RequireUseWarnings]

use v5.18;  # minimum for Object::Pad

package Weather::GHCN::App::Fetch;

our $VERSION = 'v0.0.009';

use feature 'signatures';
no warnings 'experimental::signatures';

########################################################################
# perlcritic rules
########################################################################

## no critic [ProhibitSubroutinePrototypes]
## no critic [ErrorHandling::RequireCarping]
## no critic [Modules::ProhibitAutomaticExportation]
## no critic [InputOutput::RequireBriefOpen]

# due to subroutine signatures, perlcritic can't seem to handle disabling
# the following warnings on the subs where they occur
## no critic [Subroutines::ProhibitExcessComplexity]

# due to use of postfix dereferencing, we have to disable these warnings
## no critic [References::ProhibitDoubleSigils]

########################################################################
# Export
########################################################################

require Exporter;

use base 'Exporter';

our @EXPORT = ( 'run' );

########################################################################
# Libraries and Features
########################################################################
use Object::Pad 0.66 qw( :experimental(init_expr) );

use Getopt::Long;
use Pod::Usage;
use Const::Fast;
use English         qw( -no_match_vars );

# cpan modules
use FindBin         qw($Bin);
use LWP::Simple;
use Path::Tiny;
use Text::Abbrev;

# modules for Windows only
use if $OSNAME eq 'MSWin32', 'Win32::Clipboard';

# conditional modules
use Module::Load::Conditional qw( can_load check_install requires );

# custom modules
use Weather::GHCN::Common    qw( :all );
use Weather::GHCN::StationTable;

########################################################################
# Global delarations
########################################################################

# is it ok to use Tk?
our $TK_MODULES = {
    'Tk'          => undef,
    'Tk::Getopt'  => undef,
};

# is it ok to use Win32::Clipboard?
our $USE_WINCLIP = $OSNAME eq 'MSWin32';
our $USE_TK      = can_load( modules => $TK_MODULES );

my $Opt;    # options object, with property accessors for each user option

# options that relate to script execution, not GHCN processing and output
my $Opt_savegui;    # file in which to save options from GUI dialog
my $Opt_gui;        # launch the GUI dialog
my $Opt_help;       # display POD documentation
my $Opt_readme;     # launch a browser displaying the GHCN readme file
my $Opt_usage;      # display a synopsis of the command line syntax
my $Opt_outclip;    # send report output to the Windows clipboard instead of STDOUT

########################################################################
# Constants
########################################################################

const my $EMPTY  => q();       # empty string
const my $SPACE  => q( );      # space character
const my $DASH   => q(-);      # dash character
const my $TAB    => qq(\t);    # tab character
const my $NL     => qq(\n);    # perl universal newline (any platform)
const my $TRUE   => 1;         # perl's usual TRUE
const my $FALSE  => not $TRUE; # a dual-var consisting of '' and 0

const my $PROFILE_FILE => '~/.ghcn_fetch.yaml';

const my $STN_THRESHOLD     => 100;     # ask if number of selected stations exceeds this

const my $STN_ID_RE     => qr{ [[:upper:]]{2} [[:alnum:]\_\-]{9} }xms;

########################################################################
# Script Mainline
########################################################################

__PACKAGE__->run( \@ARGV ) unless caller;

=head1 SUBROUTINES

=head2 run ( \@ARGV, stdin => 0 )

Invoke this subroutine, passing in a reference to @ARGV, in order to
fetch NOAA GHCN station data or daily weather data.

See ghnc_fetch.pl -help for details.

Stations are filtered by various options, such as -country and -location.
But Fetch->run can also receive a list of station id's via a pipe or
a file.  To enable this feature, set the B<stdin> parameter to 1 (true).

When calling Fetch->run inside a test script, it's usually best to leave
this option disabled as some test harnesses may fool the algorithm used
to detect stdin from a file or pipe.  This can be done by omitting
the stdin => <bool> parameter, or setting it to false.


=cut

sub run ($progname, $argv_aref, %args) {

    local @ARGV = $argv_aref->@*;

    # these persist across calls to run() in the unit tests, so we
    # need to reset them each time
    $Opt_savegui = $FALSE;
    $Opt_gui     = $FALSE;     
    $Opt_help    = $FALSE;    
    $Opt_readme  = $FALSE;  
    $Opt_usage   = $FALSE;   
    $Opt_outclip = $FALSE; 

    my $ghcn = Weather::GHCN::StationTable->new;

    $ghcn->tstats->start('_Overall');

    Getopt::Long::Configure ('pass_through');

    # If the first command line argument is a report_type, remove and save it
    my $report_type;
    if (@ARGV > 0 and $ARGV[0] =~ m{ \A [^-][[:alpha:]]+ \b }xms ) {
        my $rt_arg = shift @ARGV;
        my $rt = Weather::GHCN::Options->deabbrev_report_type( $rt_arg );
        $report_type = $rt // $rt_arg;
    }

    # record the number of command line arguments before they are removed by GetOptions
    my $argv_count = @ARGV;

    my %script_args = (
        'gui'       => \$Opt_gui,
        'outclip'   => \$Opt_outclip,
        'help'      => \$Opt_help,
        'usage|?'   => \$Opt_usage,
        'savegui:s' => \$Opt_savegui,   # file for options load/save
        'readme'    => \$Opt_readme,
    );

    # parse out the script options into $Opt_ fields, letting the rest
    # pass through to get_user_options below
    GetOptions( %script_args );

    if ($Opt_outclip and not $USE_WINCLIP) {
        die "*E* -outclip not available (needs Win32::Clipboard)\n";
    }

    my $ghcn_fetch_pl = path($Bin, '..', 'bin', 'ghcn_fetch')->absolute->stringify;

    if ( $Opt_help ) {
        pod2usage( { -verbose => 2, -exitval => 'NOEXIT', -input => $ghcn_fetch_pl } );
        return;
    }
    if ( $Opt_usage ) {
        pod2usage( { -verbose => 1, -exitval => 'NOEXIT', -input => $ghcn_fetch_pl } );
        return;
    }

    # launch the default browser with the NOAA Daily readme.txt file content
    if ( $Opt_readme ) {
        my $readme_uri = 'https://www1.ncdc.noaa.gov/pub/data/ghcn/daily/readme.txt';
        say 'Source: ', $readme_uri;
        say $EMPTY;
        getprint $readme_uri;
        return;
    }

    # Default to -gui if no command line arguments were provided and
    # we aren't taking input from a pipe or file.
    # PBP recommends using IO::Interactive::is_interactive rather than -t
    # because it better deals with ARGV magic; but here we just need to
    # know if *STDIN is pointing at the terminal so we suppress the
    # perlcritic warning.

    ## no critic [ProhibitInteractiveTest]
    # uncoverable branch true
    $Opt_gui = 1 if $USE_TK and $argv_count == 0 and -t *STDIN;

    my $user_opt_href = get_user_options($Opt_savegui);

    $user_opt_href->{report} = $report_type
        if defined $report_type;

    $user_opt_href->{profile} //= $PROFILE_FILE;

    die '*E* unrecognized options: ' . join $SPACE, @ARGV
        if @ARGV;

    my @errors;
    ($Opt, @errors) = $ghcn->set_options( $user_opt_href->%* );

    die join qq(\n), @errors, qq(\n)
        if @errors;

    my ( $output, $new_fh, $old_fh );
    if ( $Opt_outclip and $USE_WINCLIP ) {
        open $new_fh, '>', \$output
            or die 'Unable to open buffer for write';
        $old_fh = select $new_fh;  ## no critic (ProhibitOneArgSelect)
    }

    # get a list of station id's from stdin if it's a pipe or file
    # (but not if stdin is pointing to the terminal)
    if ( $args{'stdin'} && ( -p *STDIN || -f *STDIN ) ) {
        my $ii;
        my %f;
        while (my $line = <STDIN>) {       ## no critic [ProhibitExplicitStdin]
            chomp;
            my @id_list = $line =~ m{ $STN_ID_RE }xmsg;
            foreach my $id ( @id_list ) {
                $f{$id}++;
                $ii++;
            }
        }
        
        if ($ii == 0) {
            die '*W* no station ids found in the input';            
        } else {
            $ghcn->stnid_filter_href( \%f );            
        }
    }

    $ghcn->load_stations;

    say {*STDERR} '*I* ', $ghcn->stn_count, ' stations found';
    say {*STDERR} '*I* ', $ghcn->stn_selected_count, ' stations match location and GSN options';
    say {*STDERR} '*I* ', $ghcn->stn_filtered_count, ' stations matched range and measurement options';

    if ($ghcn->stn_filtered_count > $STN_THRESHOLD ) {
        if (-t *STDIN) {                
            print {*STDERR} ">>>> There are a lot of stations to process. Continue (y/n)?\n>>>> ";
            my $reply = <*STDIN>;
            chomp $reply;
            exit if $reply =~ m{ \A ( n | no ) }xmsi;
        } else {
            die '*E* too many stations to process';
        }
    }

    if ( $Opt->report eq 'kml' ) {
        say $ghcn->report_kml;
        goto WRAP_UP;
    }
    elsif ( $Opt->report eq 'url' ) {
        say $ghcn->report_urls;
        goto WRAP_UP;
    }
    elsif ( $Opt->report eq 'curl' ) {
        say $ghcn->report_urls( curl => 1 );
        goto WRAP_UP;
    }
    elsif ( $Opt->report eq 'stn' ) {
        say $ghcn->get_stations( kept => 1 );
        goto WRAP_UP;        
    }
    elsif ( $Opt->report eq 'id' ) {
        my @stn_list = $ghcn->get_stations( list => 1, kept => 1, no_header => 1 );
        my @id_list = map { $_->[0] } @stn_list;
        say join $NL, @id_list;
        goto WRAP_UP;        
    }

    if ($Opt->report) {
        say $ghcn->get_header;

        # this prints detailed station data if $Opt->report eq 'detail'
        $ghcn->load_data(
            # set a callback routine for printing progress messages
            progress_sub => sub { say {*STDERR} @_ },
            # set a callback routine for printing rows when -report detail
            row_sub      => sub { say join "\t", @{ $_[0] } },
        );

        if ($Opt->report eq 'detail' and $Opt->nogaps) {
            say $ghcn->get_missing_rows;
        }

        # these only do something when $Opt->report ne 'detail'
        $ghcn->summarize_data;
        say $ghcn->get_summary_data;
        say $EMPTY;

        goto WRAP_UP if $Opt->dataonly;

        say $EMPTY;
        say $ghcn->get_footer;

        say $EMPTY;
        say $ghcn->get_flag_statistics;
    }

    say $EMPTY;
    say $ghcn->get_stations( kept => 1 );

    my @rejected = $ghcn->get_stations( list => 1, kept => 0, no_header => 1 );
    if (@rejected) {
        say $EMPTY;
        say 'Stations that failed to meet range or quality criteria:';
        say tsv(\@rejected);
    }

    if ( $ghcn->has_missing_data ) {
        warn '*W* some data was missing for the stations and date range processed' . $NL;
        say $EMPTY;
        say $ghcn->get_missing_data_ranges;
    }

    $ghcn->tstats->stop('_Overall') ;
    $ghcn->tstats->finish;

    say $EMPTY;
    say $ghcn->get_options;

    say $EMPTY;
    say 'Script:';
    say $TAB, $PROGRAM_NAME;
    say "\tWeather::GHCN::StationTable version " . $Weather::GHCN::StationTable::VERSION;
    say $TAB, 'Cache directory: ' . $ghcn->cachedir;
    say $TAB, 'Profile file: ' . $ghcn->profile_file;

    if ( $Opt->performance ) {
        say $EMPTY;
        say sprintf 'Timing statistics (ms) and memory [bytes]';
        say $ghcn->get_timing_stats;

        say $EMPTY;
        say $ghcn->get_hash_stats;
    }

WRAP_UP:
    # send output to the Windows clipboard
    if ( $Opt_outclip and $USE_WINCLIP ) {
        Win32::Clipboard->new()->Set( $output );
        select $old_fh;     ## no critic [ProhibitOneArgSelect]
    }

    return;
}

########################################################################
# Subroutines
########################################################################

=head2 get_user_options ( $optfile=undef )

Fetch.pm uses B<get_user_options()> to either get user options
via B<Tk::GetOptions> -- if it is installed -- or via B<Getopt::Long>.

=cut

sub get_user_options ( $optfile=undef ) {

    my $user_opt_href = $Opt_gui
                      ? get_user_options_tk($optfile)
                      : get_user_options_no_tk($optfile)
                      ;

    return $user_opt_href;
}

=head2 get_user_options_no_tk ( $optfile=undef )

This function obtains user options from @ARGV by calling B<Getopt::Long>
B<GetOptions> using a list of option definitions obtained by calling
B<Weather::GHCN::Options->get_getopt_list()>.  The options (and their values)
are extracted from @ARGV and put in a hash, a reference to which is
then returned.

This function is called when the GUI is not being used.  The $optfile
argument, if provided, is assumed to be a file saved from a GUI
invocation and will be eval'd and used as the options list.

=cut

sub get_user_options_no_tk ( $optfile=undef ) {

    my @options = ( Weather::GHCN::Options->get_getopt_list() );

    if ($optfile) {
        my $saved_opt_perlsrc = join $SPACE, path($optfile)->lines( {chomp=>1} );
        my $loadoptions;

        ## no critic [ProhibitStringyEval]
        ## no critic [RequireCheckingReturnValueOfEval]
        eval $saved_opt_perlsrc;

        return $loadoptions;
    }

    my %opt;
    GetOptions( \%opt, @options);

    return \%opt;
}

=head2 get_user_options_tk ( $optfile=undef )

This function returns a reference to a hash of user options obtained
by calling B<Tk::Getopt>.  This may launch a GUI dialog to collect
the options.

The optional $optfile argument specifies a filename which
B<Tk::GetOptions> can use to store or load options.

=cut

sub get_user_options_tk ( $optfile=undef ) {

    if (not $USE_TK) {
        die '*E* -gui option unavailable -- try installing Tk and Tk::Getopt';
    }

    my %opt;

    my @opttable = ( Weather::GHCN::Options->get_tk_options_table() );

    my $optobj = Tk::Getopt->new(
                -opttable => \@opttable,
                -options => \%opt,
                -filename => $optfile);

    $optobj->set_defaults;     # set default values

    $optobj->load_options      # Tk:Getopt configuration file
        if defined $optfile and -e $optfile;

    $optobj->get_options;      # command line

    $optobj->process_options;  # process callbacks, check restrictions ...

    if ($Opt_gui) {
        my $top = MainWindow->new;
        $top->geometry('500x300+300+200');
        $top->title('GHCN Daily Parser');

        my $retval = $optobj->option_dialog(
            $top,
            -toplevel => 'Frame',
            -buttons => [qw/ok cancel save/], # not using cancel apply undo save defaults
            -statusbar => 1,
            -wait => 1,
            -pack => [-fill => 'both', -expand => 1],
        );

        die "*I* action cancelled\n" if $retval and $retval eq 'cancel';
    }

    return \%opt;
}

=head1 AUTHOR

Gary Puckering (jgpuckering@rogers.com)

=head1 LICENSE AND COPYRIGHT

Copyright 2022, Gary Puckering

=cut

1;
