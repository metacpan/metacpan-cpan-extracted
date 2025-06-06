BEGIN {
  use strict; use warnings;
  unless(eval q{ use 5.020; 1}) {
    print "Perl 5.020 or better required\n";
    exit;
  }
}
# This file was automatically generated by Dist::Zilla::Plugin::Author::Plicease::MakeMaker v2.62.
use strict;
use warnings;
use 5.020;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT"           => "Perl FFI interface to the Hunspell library",
  "AUTHOR"             => "Graham Ollis <plicease\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "FFI::CheckLib"       => "0.27"
  },
  "DISTNAME"         => "Text-Hunspell-FFI",
  "LICENSE"          => "perl",
  "MIN_PERL_VERSION" => "5.020",
  "NAME"             => "Text::Hunspell::FFI",
  "PM"               => {
    "lib/Text/Hunspell/FFI.pm" => "\$(INST_LIB)/Text/Hunspell/FFI.pm"
  },
  "PREREQ_PM" => {
    "FFI::CheckLib" => "0.27",
    "FFI::Platypus" => "1.00"
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.98"
  },
  "VERSION" => "0.04",
  "test"    => {
    "TESTS" => "t/*.t"
  }
);

my %FallbackPrereqs = (
  "FFI::CheckLib" => "0.27",
  "FFI::Platypus" => "1.00",
  "Test::More"    => "0.98"
);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.039
if ( !eval { require FFI::CheckLIb; FFI::CheckLib::check_lib( lib => '*', verify => sub { $_[0] =~ /hunspell/ }, symbol => "Hunspell_create" ) } ) {
  requires( 'Alien::Hunspell', 0 );
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

# inserted by Dist::Zilla::Plugin::DynamicPrereqs 0.039
sub _add_prereq {
  my ( $mm_key, $module, $version_or_range ) = @_;
  $version_or_range ||= 0;
  warn "$module already exists in $mm_key (at version $WriteMakefileArgs{$mm_key}{$module}) -- need to do a sane metamerge!"
    if exists $WriteMakefileArgs{$mm_key}{$module}
    and $WriteMakefileArgs{$mm_key}{$module} ne '0'
    and $WriteMakefileArgs{$mm_key}{$module} ne $version_or_range;
  warn "$module already exists in FallbackPrereqs (at version $FallbackPrereqs{$module}) -- need to do a sane metamerge!"
    if exists $FallbackPrereqs{$module} and $FallbackPrereqs{$module} ne '0'
    and $FallbackPrereqs{$module} ne $version_or_range;
  $WriteMakefileArgs{$mm_key}{$module} = $FallbackPrereqs{$module} = $version_or_range;
  return;
}

sub requires { goto &runtime_requires }

sub runtime_requires {
  my ( $module, $version_or_range ) = @_;
  _add_prereq( PREREQ_PM => $module, $version_or_range );
}