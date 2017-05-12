package PerlTidy::Options;

use warnings;
use strict;

use Data::Dumper;

use PerlTidy::Run;

use Log::Log4perl qw(get_logger);

# types are
# posInteger - 0..+ - default is value listed
# undef - option has effect if preent, takes no parameters
# TODO - flag - option takes -X flags - TODO
# string -  a ... string

# rather than leave the order of the sections upto the hash retrieval order,
# we explicitly return the list ordering we require - careful if
# new versions of perltidty introduce new formatting sections.

my @sections        = ();
my %nameType        = (); # contains option names and the values they can take
my %nameSection     = (); # contains option names and the section they are in
my %sectionNameType = (); # HoH of sections, the options in that section and the values they can take
my %nameRange       = (); # some options are more than just string, int or boolean - they are here
my %nameDefault     = ();

# ask PerlTidy::Run module everything it knows about options and defaults
# and populate data structures as required.
# There may be strong coupling between PerlTidy::Run and PerlTidy::Options, but they cooperate a lot
# and we are trying to isolate interactions with executing perltidy to PerlTidy::Run, and handling those perltidy's options to here

INIT {
  PerlTidy::Run->collectOptionStructures(
					 types           => \%nameType,
					 sections        => \%nameSection,
					 ranges          => \%nameRange,
					 defaults        => \%nameDefault,
					 sectionNameType => \%sectionNameType,
					 sectionList     => \@sections,
					);
}

sub getSections {
  return @sections;
}

sub getSection {
  my (undef, %args) = @_;

  my ($name) = @args{qw(name)};

  return unless $name and exists $nameSection{$name};

  return $nameSection{$name};
}

sub getEntries {
  my (undef, %args) = @_;

  my ($section) = @args{qw(section)};

  return keys %{$sectionNameType{$section}};
}

sub getValueType {
  my (undef, %args) = @_;

  my ($section, $entry, $asReference) = @args{qw(section entry asReference)};

  my $type = $sectionNameType{$section}{$entry};

  if ($asReference) {
    return $type;
  }  else {
    return ref($type) || $type;
  }
}

# same as getValueType, but doesnt need a section
sub getType {
  my (undef, %args) = @_;

  my ($entry) = @args{qw( entry )};

  return $nameType{$entry};
}

sub getDefaultValue {
  my (undef, %args) = @_;

  my ($entry) = @args{qw(entry)};

  return unless defined $entry;;

  if(exists $nameDefault{$entry}) {
    return $nameDefault{$entry};
  } elsif ( exists $nameRange{$entry}) {

    # is a ref and is therefore an array ref

    # if this is a request for the output-line-endings default, lets do a little work
    # to provide a useful default for the platform we're running on.
    # also, move the platform to the top of the list

    # note : output-line-endings is currently unsupported in tidyview

    if ($entry eq 'output-line-ending') {
      my $platform =
	($^O =~ m/(?:dos)/i  ) ? 'dos' :
	  ($^O =~ m/(?:win32)/i) ? 'win' :
	    ($^O eq 'MacOS'      ) ? 'mac' : 'unix';

      __PACKAGE__->_reorderEntries(
				   listRef   => $nameRange{$entry},
				   toBeMoved => $platform
				  );

      return $platform;
    }

    # just return the first one in the list
    return $nameRange{$entry}->[0];

  } else {

    # not in defaults or range.
    # set a value of '' for string
    # and 0 for boolean and integer

    my $type = $nameType{$entry};

    return unless defined $type;

    return $type =~ m/^=(?:!|i)$/ ? 0 : '';
  }
}

sub _reorderEntries {
  my (undef, %args) = @_;

  my ($list, $toBeMoved) = @args{qw(listRef toBeMoved)};

  @$list = ($toBeMoved, grep {$_ ne $toBeMoved} @$list); # remove from list
}

1;
