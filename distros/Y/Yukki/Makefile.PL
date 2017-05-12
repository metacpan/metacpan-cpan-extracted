
use strict;
use warnings;

use 5.012001;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share module => "Yukki::Web", "skel";


my %WriteMakefileArgs = (
  "ABSTRACT" => "Yet Uh-nother wiki",
  "AUTHOR" => "Andrew Sterling Hanenkamp <hanenkamp\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "File::ShareDir::Install" => "0.03"
  },
  "DISTNAME" => "Yukki",
  "EXE_FILES" => [
    "bin/yukki-add-user",
    "bin/yukki-git-init",
    "bin/yukki-passwd",
    "bin/yukki-setup",
    "bin/yukki.psgi"
  ],
  "LICENSE" => "perl",
  "NAME" => "Yukki",
  "PREREQ_PM" => {
    "CHI" => 0,
    "Cache::FastMmap" => 0,
    "Class::Load" => 0,
    "Crypt::SaltedHash" => 0,
    "DateTime::Format::Mail" => 0,
    "Digest::SHA1" => 0,
    "Email::Address" => 0,
    "File::Copy::Recursive" => 0,
    "File::Path" => 0,
    "File::ShareDir" => 0,
    "Git::Repository" => "v1.18.0",
    "HTTP::Throwable" => 0,
    "IO::Prompter" => 0,
    "JSON" => 0,
    "LWP::MediaTypes" => 0,
    "List::MoreUtils" => 0,
    "List::Util" => 0,
    "Moose" => 0,
    "Moose::Role" => 0,
    "Moose::Util::TypeConstraints" => 0,
    "MooseX::Params::Validate" => 0,
    "MooseX::Traits" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "MooseX::Types::Path::Class" => 0,
    "MooseX::Types::Structured" => 0,
    "MooseX::Types::URI" => 0,
    "Number::Bytes::Human" => 0,
    "Path::Class" => 0,
    "Path::Router" => 0,
    "Path::Router::Route" => 0,
    "Path::Router::Route::Match" => 0,
    "Plack::App::File" => 0,
    "Plack::Builder" => 0,
    "Plack::Request" => 0,
    "Plack::Response" => 0,
    "Plack::Session::Store::Cache" => 0,
    "Scalar::Util" => 0,
    "Spreadsheet::Engine" => 0,
    "StackTrace::Auto" => 0,
    "Sub::Exporter" => 0,
    "Syntax::Highlight::Engine::Kate" => 0,
    "Syntax::Highlight::Engine::Kate::All" => 0,
    "Template::Semantic" => 0,
    "Text::MultiMarkdown" => 0,
    "Throwable" => 0,
    "Try::Tiny" => 0,
    "URI::Escape" => 0,
    "XML::Twig" => 0,
    "YAML" => 0,
    "autodie" => 0
  },
  "TEST_REQUIRES" => {
    "File::Temp" => 0,
    "IPC::Run3" => 0,
    "Probe::Perl" => 0,
    "Test::Exception" => 0,
    "Test::Moose" => 0,
    "Test::More" => 0,
    "Test::Script" => 0,
    "lib" => 0
  },
  "VERSION" => "0.140290",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  my $tr = delete $WriteMakefileArgs{TEST_REQUIRES};
  my $br = $WriteMakefileArgs{BUILD_REQUIRES};
  for my $mod ( keys %$tr ) {
    if ( exists $br->{$mod} ) {
      $br->{$mod} = $tr->{$mod} if $tr->{$mod} > $br->{$mod};
    }
    else {
      $br->{$mod} = $tr->{$mod};
    }
  }
}

unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

{
package
MY;
use File::ShareDir::Install qw(postamble);
}


