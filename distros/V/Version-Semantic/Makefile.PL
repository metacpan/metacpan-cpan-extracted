use strict;
use warnings;

use ExtUtils::MM          ();
use File::Spec::Functions qw( catfile );

my @main_module_namespace = qw( Version Semantic );
my $release_status        = 'stable';                 # Transitions: unstable => testing => stable
my $pre_release_number    = 1;

my $distname            = join '-',  @main_module_namespace;
my $main_module         = join '::', @main_module_namespace;
my $main_module_file    = catfile( @main_module_namespace ) . '.pm';
my $main_module_podfile = catfile( @main_module_namespace ) . '.pod';
# We are not using
# VERSION_FROM  => catfile( 'lib', $main_module_file )
# because we have to set the main module version in META_MERGE/provides too
my $main_module_version = MM->parse_version( catfile( 'lib', $main_module_file ) );

my %att = (
  NAME          => $main_module,
  AUTHOR        => 'Sven Willenbuecher <sven.willenbuecher@gmx.de>',
  VERSION       => $main_module_version,
  ABSTRACT_FROM => catfile( 'lib', $main_module_podfile ),
  # Another valid license string is "restricted"
  # https://metacpan.org/pod/CPAN::Meta::Spec#license
  LICENSE          => 'perl_5',
  MIN_PERL_VERSION => '5.010000',
  DISTNAME         => $distname,
  DISTVNAME        =>
    join( '-', $distname, $main_module_version, ( $release_status ne 'stable' ? "TRIAL$pre_release_number" : () ) )
  ,    # Related to the below release_status metadata field
  EXE_FILES  => [ glob( join( ' ', map { catfile( $_, '*' ) } qw( bin script ) ) ) ],
  META_MERGE => {
    'meta-spec'    => { version => 2 },
    release_status => $release_status,
    provides       => {
      $main_module => {
        file    => catfile( 'lib', $main_module_file ),
        version => $main_module_version
      }
    },
    resources => {
      repository => {
        type => 'git',
        url  => "https://github.com/XSven/$distname.git",
        web  => "https://github.com/XSven/$distname"
      },
      bugtracker => {
        web => "https://github.com/XSven/$distname/issues"
      }
    }
  },
  # check ExtUtils::MakeMaker Changes
  NORECURS     => 1,
  NO_PERLLOCAL => 1,
  clean        => { FILES                => "$distname*" },
  dist         => { TARFLAGS             => 'cf', COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
  realclean    => { FILES                => 'cover_db local' },
  test         => { RECURSIVE_TEST_FILES => 1 }
);

# Makefile.PL as a modulino
# https://www.masteringperl.org/2015/01/makefile-pl-as-a-modulino/
if ( caller() ) {
  *WriteMakefile = sub { +{ @_ } }    # \%att
} else {
  require ExtUtils::MakeMaker::CPANfile;
  ExtUtils::MakeMaker::CPANfile->import
}
WriteMakefile( %att )
