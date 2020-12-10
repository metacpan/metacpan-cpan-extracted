#! perl

use strict;
use warnings;
use 5.008001;
use ExtUtils::MakeMaker 6.5503;

my $PERL_version = '5.008001';  # can't use in "use" statement above! eval?
                                # could read from .perl-version file otherwise
my $MakeMaker_version = '6.5503';
my $version = '1.03';           # PDFbuild.pl updates from 'version' file

# optional libraries... prompt user whether or not to install
# nice to have but not vital for many users
#   if one fails to install, it might alarm the user, but installation of 
#     PDF::Builder can still proceed
#   user can remove any optional installed library if they don't need it
#     and want to reclaim the space
#   update t/00-all-usable.t to exclude modules using these libraries!
my @choice_list = ( # use array to guarantee order
	# 'a' and 'n' are reserved, do not use as key [0]
	# [1] is actual library name [2] is minimum version [3] description
# ["t", "Graphics::TIFF", 7, "TIFF image support"],
        # improved TIFF image processing. DON'T FORGET TO UPDATE VERSION in
	#   t/00-all-usable.t, lib/PDF/Builder.pm
# ["p", "Image::PNG::Libpng", 0.47, "PNG image support"],
        # advanced/fast PNG image processing. DON'T FORGET TO UPDATE VERSION in
	#   t/00-all-usable.t, lib/PDF/Builder.pm
# ["h", "HarfBuzz::Shaper", 0.23, "complex script support"],
        # text shaping for Latin script ligatures and kerning, and for 
	# many complex scripts both LTR and RTL directions.
);

# EVERY RELEASE: check https://www.cpan.org/src/ "First release in each branch
#   of Perl" (NOT "Latest releases in each branch of Perl"!) and subtract 
#   6 years to get date of oldest release, and then go one release before that. 
#   Update the required Perl minimum here and in .perl-version, dist.ini[.old], 
#   and .travis.yml[.HOLD], and commit to repository.
#   Can't fully automate, since "use $PERL_version;" is invalid (eval?).
#   Would be nice to read cpan First Release and figure out min Perl version.
#
#   Perhaps build Makefile.PL (and some other files?) during build process,
#   so proper Perl version can be inserted into a template then? Perl version
#   could come from .perl-version (reformatted), or scraped from cpan.org page.

# for future consideration
#my $master  = 'lib/Text/KnuthPlass.pm';
#my $version = MM->parse_version($master);

# prompt routine lifted from IO::Socket::SSL, and modified to allow
# arbitrary choices (not just y and n). NOT checked: that default is
# among choices, and default is lowercase!
# for the original Y/n, choices 'yn' max 1 default 'y' or 'n'
local $| = 1;

my $make_choice = sub {
    my ($msg, $choices, $max, $default) = @_;
    return $default if defined $default && $ENV{PERL_MM_USE_DEFAULT};
    # Taken from ExtUtils::MakeMaker 6.16 (Michael Schwern) so that
    # the prompt() function can be emulated for older versions of ExtUtils::MakeMaker.
    while ( -t STDIN && (-t STDOUT || !(-f STDOUT || -c STDOUT))) {
	print "$msg ";
	my $choice = <>;
	$choice =~ s/\s//g;  # strip off whitespace
	if (length($choice) > $max) { next; } # too many entries?
	$choice ||= $default;
	next if $choice !~ m/^([$choices]+)$/i;
	return lc($1);
    }

    return $default;
};

my %WriteMakefileArgs =
(
 NAME		=> "Text::KnuthPlass",
 DISTNAME       => "Text-KnuthPlass",
 VERSION        => $version,
# ABSTRACT_FROM	 => $master,
 ABSTRACT       => "Paragraph shaping (line breaking) with Knuth-Plass TeX algorithm",

 AUTHOR		=> 'Phil Perry <pmperry at cpan.org>',
 LICENSE	=> "Perl",
 MIN_PERL_VERSION	=> $PERL_version,
 INSTALLDIRS	=> "site",

 CONFIGURE_REQUIRES => {
    "ExtUtils::MakeMaker" => $MakeMaker_version,
 },

# BUILD_REQUIRES => {  # mandatory prereqs listed here
# },

 TEST_REQUIRES	=> {
    "JSON::Syck" => 0,

   #"Test::More" => 0,   is core
   #"Data::Dumper" => 0,   is core
   #"Test::Pod" => 0,    author tests, non-core
   #"Test::Pod::Coverage" => 0,    author tests, non-core
   #"Pod::Coverage" => 0,    author tests, non-core
 },

 PREREQ_PM => {
    "Class::Accessor" => 0,
    "Text::Hyphen" => 0,

    # === found in CORE, so no need to explicitly list
    #"constant" => 0,
    #"Data::Dumper" => 0,
    #"Carp" => 0,
  },

  META_MERGE        => {

    "meta-spec" => { version => 2 },

    resources => {

      homepage => "https://metacpan.org/search?q=Text%3A%3AKnuthPlass, https://www.catskilltech.com",

      repository => {
          type => 'git',
          url => 'git://github.com/PhilterPaper/Text-KnuthPlass.git',
          web => 'https://github.com/PhilterPaper/Text-KnuthPlass',
      },

      bugtracker => {
	  web => 'https://github.com/PhilterPaper/Text-KnuthPlass/issues',
	  mailto => 'pmperry [at] cpan.org',
      },

    },

    # recommends (optional prereqs) goes here

  },

);

# restore if make use of Windows-only prerequisites
#if ( $^O eq 'MSWin32' ) {
#	$WriteMakefileArgs{PREREQ_PM}{'Win32::TieRegistry'} = '0';
#}

# enable if required for build on Mac
#if ( $^O eq 'MacOS' ) {
#	$WriteMakefileArgs{PREREQ_PM}{'MacPerl'} = '0';
#}

my ($prompt, $i, $c, $all_list);
my $list_len = scalar(@choice_list);
# build multi-line prompt and output it
if (scalar @choice_list > 0) {  # in case all disabled!
  $prompt = "Attempt to install or update optional prereq libraries?\n".
    " a (default) = install all choices listed below\n".
    " n = do NOT install any of them\n".
    "   or enter 1 to $list_len of the following choices:\n";
  $all_list = '';
  for ($i = 0; $i < $list_len; $i++) {
    $all_list .= $choice_list[$i][0];
    $prompt .= " $choice_list[$i][0] = install/update $choice_list[$i][1] ($choice_list[$i][3] support)";
    if ($i < $list_len-1) { $prompt .= "\n"; }
  }
  $prompt .= " [A|n|{".join('|', split //,$all_list)."}]";

  $c = $make_choice->( $prompt, 'an'.$all_list, $list_len, 'a' );
} else {
  $c = 'n'; # default if nothing available
}
# $c should have one or more of a,n (contradictory!) t,p,h

if (scalar @choice_list > 0) {
  if ($c !~ m/n/) { # remind user that librarie(s) to be installed/updated
print <<'END';
===========================================================================
The installation process will attempt to install or update several OPTIONAL
prerequisite packages. If one or more should fail to install, Don't Panic
-- you will still be able to run PDF::Builder, but may not be able to use 
some advanced features. See the README file for more information.
===========================================================================
END
    if ($c =~ m/a/) { $c = $all_list; }

    # $c is one or more choices (no 'a' or 'n')
    # build 'recommends' entry into %WriteMakefileArgs
    for ($i = 0; $i < $list_len; $i++) {
      if (index($c, $choice_list[$i][0]) < 0) { next; }
      $WriteMakefileArgs{'META_MERGE'}{'recommends'}{
        "$choice_list[$i][1]"} = $choice_list[$i][2];
    }
  }
}

WriteMakefile(%WriteMakefileArgs);
#use Data::Dumper;    # for debugging
#my $d = Data::Dumper->new([\%WriteMakefileArgs]);
#print $d->Dump();
