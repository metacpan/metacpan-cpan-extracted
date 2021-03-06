use lib 'inc';
use Devel::AssertOS qw[MSWin32];
# This file was automatically generated by Dist::Zilla::Plugin::MakeMaker v6.005.
use strict;
use warnings;

use 5.008009;

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
  "ABSTRACT" => "Perl classes to access Microsoft SQL Server 2000 DTS Packages",
  "AUTHOR" => "Alceu Rodrigues de Freitas Junior <arfreitas\@cpan.org>",
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0
  },
  "DISTNAME" => "Win32-SqlServer-DTS",
  "LICENSE" => "gpl",
  "MIN_PERL_VERSION" => "5.008009",
  "NAME" => "Win32::SqlServer::DTS",
  "PREREQ_PM" => {
    "Class::Accessor" => "0.25",
    "Class::Publisher" => "0.2",
    "Data::Dumper" => 0,
    "DateTime" => "0.35",
    "File::Spec" => 0,
    "Hash::Util" => 0,
    "Params::Validate" => "1.24",
    "Win32::OLE" => "0.1704",
    "Win32::OLE::Variant" => 0,
    "XML::Simple" => "2.18",
    "base" => 0,
    "constant" => 0
  },
  "TEST_REQUIRES" => {
    "ExtUtils::MakeMaker" => 0,
    "File::Spec" => 0,
    "Test::Exception" => "0.43",
    "Test::More" => 0
  },
  "VERSION" => "0.13",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


my %FallbackPrereqs = (
  "Class::Accessor" => "0.25",
  "Class::Publisher" => "0.2",
  "Data::Dumper" => 0,
  "DateTime" => "0.35",
  "ExtUtils::MakeMaker" => 0,
  "File::Spec" => 0,
  "Hash::Util" => 0,
  "Params::Validate" => "1.24",
  "Test::Exception" => "0.43",
  "Test::More" => 0,
  "Win32::OLE" => "0.1704",
  "Win32::OLE::Variant" => 0,
  "XML::Simple" => "2.18",
  "base" => 0,
  "constant" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);
