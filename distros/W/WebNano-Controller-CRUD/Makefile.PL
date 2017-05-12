
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A base controller implementing CRUD operations (EXPERIMENTAL!)",
  "AUTHOR" => "Zbigniew Lukasiak <zby\@cpan.org>",
  "BUILD_REQUIRES" => {
    "Config::Any" => 0,
    "DBIx::Class" => 0,
    "DBIx::Class::Schema" => 0,
    "DateTime" => 0,
    "File::Copy" => 0,
    "HTML::FormHandler::Model::DBIC" => 0,
    "HTML::FormHandler::Moose" => 0,
    "HTML::FormHandler::Render::Simple" => 0,
    "HTTP::Request::Common" => 0,
    "Plack::Test" => 0,
    "Test::More" => 0,
    "WebNano" => 0,
    "WebNano::Renderer::TT" => 0,
    "base" => 0,
    "overload" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "WebNano-Controller-CRUD",
  "EXE_FILES" => [],
  "LICENSE" => "artistic_2",
  "NAME" => "WebNano::Controller::CRUD",
  "PREREQ_PM" => {
    "Class::MOP" => 0,
    "Config::General" => 0,
    "Cwd" => 0,
    "DBIx::Class" => 0,
    "DateTime::Format::SQLite" => 0,
    "File::Spec::Functions" => 0,
    "HTML::FormHandler::Model::DBIC" => 0,
    "HTML::FormHandler::Moose" => 0,
    "Moose" => 0,
    "MooseX::NonMoose" => 0,
    "WebNano" => "0.007",
    "WebNano::Controller" => 0,
    "WebNano::Renderer::TT" => 0
  },
  "VERSION" => "0.007",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


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



