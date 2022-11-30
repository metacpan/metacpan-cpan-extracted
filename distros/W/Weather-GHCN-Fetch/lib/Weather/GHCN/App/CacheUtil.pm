# Weather::GHCN::CacheUtil.pm - cache utility

## no critic (Documentation::RequirePodAtEnd)

=head1 NAME

Weather::GHCN::App::CacheUtil - Show or clean up cache content

=head1 VERSION

version v0.0.011

=head1 SYNOPSIS

    use Weather::GHCN::App::CacheUtil;

    Weather::GHCN::App::CacheUtil->run( \@ARGV );

See ghcn_cacheutil -help for details.

=cut

########################################################################
# Pragmas
########################################################################

# these are needed because perlcritic fails to detect that Object::Pad handles these things
## no critic [ValuesAndExpressions::ProhibitVersionStrings]

use v5.18;
use warnings;

package Weather::GHCN::App::CacheUtil;

our $VERSION = 'v0.0.011';

use feature 'signatures';
no warnings 'experimental::signatures';

########################################################################
# perlcritic rules
########################################################################

## no critic [Subroutines::ProhibitSubroutinePrototypes]
## no critic [ErrorHandling::RequireCarping]
## no critic [Modules::ProhibitAutomaticExportation]

# due to use of postfix dereferencing, we have to disable these warnings
## no critic [References::ProhibitDoubleSigils]

########################################################################
# Export
########################################################################

require Exporter;

use base 'Exporter';

our @EXPORT = ( 'run' );

########################################################################
# Libraries
########################################################################
use English         qw( -no_match_vars ) ;
use Getopt::Long    qw( GetOptionsFromArray );
use Pod::Usage;
use Const::Fast;
use Hash::Wrap      {-lvalue => 1, -defined => 1, -as => '_wrap_hash'};
use Path::Tiny 0.122;
use Weather::GHCN::Common       qw(commify);
use Weather::GHCN::Station;
use Weather::GHCN::StationTable;

# modules for Windows only
use if $OSNAME eq 'MSWin32', 'Win32::Clipboard';

########################################################################
# Global delarations
########################################################################

# is it ok to use Win32::Clipboard?
our $USE_WINCLIP = $OSNAME eq 'MSWin32';

our $Opt;   # declared as 'our' for r/w access from 94_ghcn_cacheutil.t

########################################################################
# Constants
########################################################################

const my $EMPTY  => q();        # empty string
const my $SPACE  => q( );       # space character
const my $COMMA  => q(,);       # comma character
const my $TAB    => qq(\t);     # tab character
const my $DASH   => q(-);       # dash character
const my $TRUE   => 1;          # perl's usual TRUE
const my $FALSE  => not $TRUE;  # a dual-var consisting of '' and 0

const my $PROFILE_FILE => '~/.ghcn_fetch.yaml';


########################################################################
# Script Mainline
########################################################################

__PACKAGE__->run( \@ARGV ) unless caller;

#-----------------------------------------------------------------------
=head1 SUBROUTINES

=head2 run ( \@ARGV )

Invoke this subroutine, passing in a reference to @ARGV, in order to
get list of cache contents or remove cache content.

See ghnc_cache.pl -help for details.

=cut

sub run ($progname, $argv_aref) {

    $Opt = get_options($argv_aref);

    my $ghcn = get_ghcn($Opt->profile, $Opt->cachedir);
    my $cache_pto = path($ghcn->cachedir);  # pto = Path::Tiny object

    if ($Opt->clean) {
        my @errors = $ghcn->cache_obj->clean_cache();
        if (@errors) {
            say {*STDERR} join "\n", @errors;
            exit 1;
        }
        return;
    }

    # send print output to the Windows clipboard if requested and doable
    outclip() if $Opt->outclip and $USE_WINCLIP;

    my $alias_href = get_alias_stnids($ghcn->profile_href);

    my $files_href = load_cached_files($ghcn, $cache_pto, $alias_href);
    
    if (keys $files_href->%* == 0) {
        say {*STDERR} '*I* cache is empty';
        return;
    }
    
    if ($Opt->remove) {
        foreach my $fileid (sort keys $files_href->%*) {
            my $file = $files_href->{$fileid};
            next unless $file->{INCLUDE};
            say {*STDERR} 'Removing ', $file->{PathObj};
            $file->{PathObj}->remove;
        }
        return;
    }

    my $total_kb = report_daily_files($files_href);

    say '';
    say "Total cache size: ", commify($total_kb);
    say 'Cache location: ', $cache_pto;

    # restore print output to stdout
    outclip() if $Opt->outclip and $USE_WINCLIP;

    return;
}

=head2 filter_files ( \%files )

Given a hash containing Path::Tiny objects representing the files
in the designed ghcn cache folder, apply the various filtering
criteria options and mark those objects which match the criteria by
inserting the key INCLUDE with value 1 in the %files entry for
that object.

Modifies the content of %files.  Void return.

=cut

sub filter_files ($files_href) {
    foreach my $fileid (sort keys $files_href->%*) {
        my $file = $files_href->{$fileid};
        my $loc = $Opt->location;

        next unless match_type( $file->{Type}, $Opt->type );

        next if $Opt->country and $file->{Country} ne $Opt->country;
        next if $Opt->state   and $file->{State}   ne $Opt->state;

        my $kb = round($file->{Size} / 1024);

        if (defined $Opt->size) {
            next unless $Opt->size <=  0 
            ? $kb <= -$Opt->size
            : $kb >=  $Opt->size;           
        }

        if (defined $Opt->age) {
            next unless $Opt->age <=  0 
            ? $file->{Age} <= -$Opt->age
            : $file->{Age} >=  $Opt->age;           
        }

        if ($Opt->invert) {
            next if $Opt->location and $file->{Location} =~ m{$loc}msi;
        } else {
            next if $Opt->location and $file->{Location} !~ m{$loc}msi;
        }
        
        $file->{INCLUDE} = 1;
    }
}

=head2 get_ghcn ($profile, $cachedir)

Returns a Weather::GHCN::StationTable object initialized with a cache
location obtained from $cachedir or, if $cachdir is undefined, from
the cachedir option defined in the user profile specified by
$profile.  If errors are encounterd, it dies and produces a list.

=cut

sub get_ghcn ($profile, $cachedir) {
    my $ghcn = Weather::GHCN::StationTable->new;

    $profile //= $PROFILE_FILE;

    my ($opt, @errors) = $ghcn->set_options(
        cachedir => $cachedir,
        profile => $profile,
    );
    die @errors if @errors;

    return $ghcn;
}

=head2 get_options ( \@ARGV )

B<get_options> encapsulates everything we need to process command line
options, or to set options when invoking this script from a test script.

Normally it's called by passing a reference to @ARGV; from a test script
you'd set up a local array variable to specify the options.

By convention, you should set up a file-scoped lexical variable named
$Opt and set it in the mainline using the return value from this function.
Then all options can be accessed used $Opt->option notation.

=cut

sub get_options ($argv_aref) {

    my @options = (
        'country:s',            # filter by country
        'state|prov:s',         # filter by state or province
        'location:s',           # filter by localtime
        'remove',               # remove cached daily files (except aliases)
        'clean',                # remove all files from the cache
        'invert|v',             # invert -location selection criteria
        'size|kb:i',            # select files by size in Kb
        'age:i',                # select file if >= age
        'type:s',               # select based on type
        'cachedir:s',           # cache location
        'profile:s',            # profile file
        'outclip',              # output data to the Windows clipboard
        'help','usage|?',       # help
    );

    my %opt;

    # create a list of option key names by stripping the various adornments
    my @keys = map { (split m{ [!+=:|] }xms)[0] } grep { !ref  } @options;
    # initialize all possible options to undef
    @opt{ @keys } = ( undef ) x @keys;

    GetOptionsFromArray($argv_aref, \%opt, @options)
        or pod2usage(2);
        
    # Make %opt into an object and name it the same as what we usually
    # call the global options object.  Note that this doesn't set the
    # global -- the script will have to do that using the return value
    # from this function.  But, what this does is allow us to call
    # $Opt->help and other option within this function using the same
    # syntax as what we use in the script.  This is handy if you need
    # to rename option '-foo' to '-bar' because you can do a find/replace
    # on '$Opt->foo' and you'll get any instances of it here as well as
    # in the script.

    ## no critic [Capitalization]
    ## no critic [ProhibitReusedNames]
    my $Opt = _wrap_hash \%opt;

    pod2usage(1)             if $Opt->usage;
    pod2usage(-verbose => 2) if $Opt->help;

    return $Opt;
}

=head2 get_alias_stnids ( \%profile )

Read the hash obtained from the user profile file and find the alias
definitions.  Return a hash of station id's that have been aliased.

=cut

sub get_alias_stnids ($profile_href) {
    return {} if not $profile_href;
    my $aliases_href = $profile_href->{aliases};
    return {} if not $aliases_href;
    my %aliases;
    foreach my $stn_str (values $aliases_href->%*) {
        my @stns = split $COMMA, $stn_str;
        foreach my $stn (@stns) {
            $aliases{$stn} = 1;
        }
    }
    return \%aliases;
}

=head2 load_cached_files ($ghcn, $cache_pto, \%alias )

Given a Weather::GHCN::StationTable object and a cache Path::Tiny
object, and a hash of which files correspond to aliased stations,
return a hash which combines the file information and the station
information (where applicable) and categorizes each entry by type:
D for daily data file, A for aliases station, and C for catalog files.

=cut

sub load_cached_files ($ghcn, $cache_pto, $alias_href) {

    my @files = $cache_pto->children;

    return {} if not @files;

    my @txtfiles;
    my %filter;
    foreach my $pto (@files) {
        my $bname = $pto->basename;
        if ( $bname =~ m{ [.]txt \Z}xms ) {
            push @txtfiles, $pto;
            next;
        }
        my $stnid = $pto->basename('.dly'); # removes the extension
        $filter{$stnid} = 1;
    }


    if (@txtfiles == 0) {
        say {*STDERR} '*W* no station catalog files (ghcnd-*.txt) in the cache - resorting to a simple file list';
        say $_->basename for @files;
        return {};
    }

    my $stations_txt = path($cache_pto, 'ghcnd-stations.txt')->slurp;

    $ghcn->stnid_filter_href( \%filter );
    $ghcn->load_stations( content => $stations_txt );

    my @stations = $ghcn->get_stations(list => 1, no_header => 1);
    my @hdr = Weather::GHCN::Station::Headings;

    my %files;
    foreach my $stn_row (@stations) {
        my %file;
        @file{@hdr} = $stn_row->@*;

        my $fileid = $file{StationId};
        my $pathobj = path($cache_pto, $fileid . '.dly');

        $file{Type} = $alias_href->{$fileid} ? 'A' : 'D';
        $file{Size} = $pathobj->size;
        $file{Age} = int -M $pathobj->stat;
        $file{PathObj} = $pathobj;
        $files{$file{StationId}} = \%file;
    }

    foreach my $pto (@txtfiles) {
        my %file;
        my $fileid = $pto->basename('.txt');
        $fileid =~ s{ \A ghcnd- }{}xms;
        $file{StationId} = $fileid;
        $file{Location} = $pto->basename;
        $file{Type} = 'C';
        $file{Size} = $pto->size;
        $file{Age} = int -M $pto->stat;
        $file{PathObj} = $pto;
        $files{$file{StationId}} = \%file;
    }

    filter_files(\%files);
    
    return \%files;
}

=head2 match_type ($file_type, $match_types)

Cache files are categorized by type:  D for .dly files, A for .dly files
that correspond to user aliases, and C for .txt files.  The user can
provide a -type option with a string to select based on type.  The
string can contain any or all of the three letters.  This function
is used to match the file type with the -type option.  Returns true
if the $file_type letter (D, A or C) is found in the $match_types
string.

=cut

sub match_type ($file_type, $match_types) {
    return $TRUE if not $match_types;
    my @types = split //, $match_types;
    my $matched = 0;
    foreach my $m (@types) {
        $matched++ if uc $m eq uc $file_type
    }
    return $matched++
}

=head2 outclip ()

When called initially, it redirects STDOUT to local variable so that
printing is saved in memory.  On the subsequent call, it writes the
content of the variable to the Windows Clipboard and resets STDOUT
to its original state (usually the terminal).

Since Windows::Clipboard is platform specific, calls to this subroutine
should conditional.  The following pattern is recommended:

    # modules for Windows only
    use if $OSNAME eq 'MSWin32', 'Win32::Clipboard';

    # is it ok to use Win32::Clipboard?
    our $USE_WINCLIP = $OSNAME eq 'MSWin32';

    # send print output to the Windows clipboard if requested and doable
    outclip() if $Opt->outclip and $USE_WINCLIP;

    ... print stuff
    
    # restore print output to stdout
    outclip() if $Opt->outclip and $USE_WINCLIP;

This subroutine relies on state variables.  It cannot be used in a 
nested fashion.  It is best confined to main:: (or the top-level 
subroutine).

=cut

sub outclip () {
    state $old_fh;
    state $output;

    if ($old_fh) {
        Win32::Clipboard->new()->Set( $output );
        select $old_fh;     ## no critic [ProhibitOneArgSelect]
    } else {
        open my $new_fh, '>', \$output
            or die 'Unable to open buffer for write';
        $old_fh = select $new_fh;  ## no critic (ProhibitOneArgSelect)
    }

    return;
}

=head2 report_daily_files ($files_href)

Given a hash of the cache file hash objects, each consisting of a
merger of file properties and station properties, this subroutine
will print a report listing those that were flagged for inclusion
by filter_files().  

Output is ordered by StationId.  Catalog (.txt) files don't have a 
station id, so short version of the filename is used.  Since those 
names are lowercase, they sort last in the the list.

The Type of the file appears in the first column:  D for daily weather
data files, A for daily weather data files that correspond to aliases
defined in the user profile, and C for catalog files.

=cut

sub report_daily_files ($files_href) {

    printf "%s %-11s %2s %2s %-9s %6s %4s %s\n", qw(T StationId Co St Active Kb Age Location);
    
    my $total_kb = 0;

    foreach my $fileid (sort keys $files_href->%*) {
        my $file = $files_href->{$fileid};
        next unless $file->{INCLUDE};

        my $kb = round($file->{Size} / 1024);
        $total_kb += $kb;
       
        no warnings 'uninitialized';
        printf "%s %-11s %2s %2s %9s %6s %4s %s\n",
            $file->{Type},
            $file->{StationId},
            $file->{Country},
            $file->{State},
            $file->{Active},
            sprintf('%6s', commify( $kb )),
            $file->{Age},
            $file->{Location},
            ;
    }

    return $total_kb;
}

=head2 round ($v)

Round $v using the half-adjust method.  Returns an integer.

=cut

sub round ($v) {
    return int($v + .5);
}

1;
