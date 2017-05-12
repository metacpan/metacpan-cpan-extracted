package PerlTidy::Run;

# all interactions with Perl::Tidy are via this module
use strict;
use warnings;

use Data::Dumper;

use Log::Log4perl qw(get_logger);

use Perl::Tidy;

use TidyView::Options;

sub execute {
  my (undef, %args) = @_;

  my ($fileToTidy) = @args{qw(file)};

  my $options = TidyView::Options->assembleOptions(separator => "\n");

  my $resultString  = "";
  my $argv          = ""; # prevent perltidy from seeing our @ARGV
  my $stderrCapture = ""; # possible error output here

  Perl::Tidy::perltidy(
		       argv        => \$argv,
		       stderr      => \$stderrCapture,
		       perltidyrc  => \$options,
		       source      => $fileToTidy,
		       destination => \$resultString
		      );


  return wantarray ? split(/^/m, $resultString) : $resultString;
}

# get all the option names, types, ranges and defaults from Perl::Tidy, and place them various data structures
# for PerlTidy::Options to work with from then on
sub collectOptionStructures {
  my (undef, %args) = @_;

  #cant create a logger - this function is called in an INIT block, so no initialisation has occurred

  my ($nameType, $nameSection, $nameRange, $nameDefault, $sectionNameType, $sectionList) = @args{qw(types
												    sections
												    ranges
												    defaults
												    sectionNameType
												    sectionList
												   )
											       };

  my $stderrCapture = "";
  my $argv          = "";

  # get the option names, ranges, types and defaults from Perl::Tidy

  Perl::Tidy::perltidy(
		       dump_getopt_flags     => $nameType,    # gives the option => type    map
		       dump_options_category => $nameSection, # gives the option => section map
		       dump_options_range    => $nameRange,   # gives the option => range   map
		       dump_options          => $nameDefault, # gives the option => default map
		       dump_options_type     => 'full',       # get map for all options, not just parsed ones
		       stderr                => \$stderrCapture,
		       argv                  => \$argv,
		      );

  die "error calling Perl::Tidy::perltidy :: $stderrCapture" if $stderrCapture;

  # extract the sections
  foreach my $name (keys %$nameSection) {
    # we need to ignore a few options for now - eventually these kind of policy decisions may be inside Perl::Tidy::perltidy()

    next if $name =~ m/^(?:entab-leading-whitespace   |
		           starting-indentation-level |
		           output-line-ending         |
		           tabs                       |
		           preserve-line-endings
		        )/x;

    my $type;

    unless (exists $nameType->{$name}) {
      warn( "Unknown value type for option $name" );
    } else {
      $type = $nameType->{$name};
    }

    if (exists   $nameRange->{$name} and
	defined  $nameRange->{$name} and
	ref($nameRange->{$name}) =~ m/^ARRAY$/) {

      # replace with the more specific range type
      $sectionNameType->{$nameSection->{$name}}->{$name} = $nameRange->{$name};

    } else {

      $sectionNameType->{$nameSection->{$name}}->{$name} = $type;

    }

  }

  {
    no warnings 'numeric';

    # we take advantage of the fact that sections have the form "number. name"

    @$sectionList = sort {$a <=> $b} keys %$sectionNameType;
  }

  # delete from sections list as that appears inthe GUI, but dont delete from sectionNameType as we
  # use that to test if a parsed option is unsupported

  shift @$sectionList; # drop off first section "I/O control"
  pop @$sectionList; # drop off last  section "Debugging"

}

# given a file handle, ask Perl::Tidy to parse the file and report on any problems
sub parseConfig {
  my (undef, %args) = @_;

  my ($fileHandle, $destination, ) = @args{qw(handle destination)};

  my $stderrCapture   = "";	# try to capture error messages
  my $argv            = "";	# do not let perltidy see our @ARGV

  Perl::Tidy::perltidy(
		       perltidyrc   => $fileHandle,
		       dump_options => $destination,
		       stderr       => \$stderrCapture,
		       argv         => \$argv,
		      );

  return $stderrCapture;
}

1;
