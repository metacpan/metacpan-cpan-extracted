
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Create text, html and xml sitemap by scanning a web site.",
  "AUTHOR" => "Alex J. G. Burzy\305\204ski <ajgb\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "HTTP::Daemon" => 0,
    "HTTP::Date" => 0,
    "HTTP::Response" => 0,
    "HTTP::Status" => 0,
    "Module::Build" => "0.3601",
    "Test::Exception" => 0,
    "Test::More" => 0,
    "Test::NoWarnings" => 0,
    "base" => 0,
    "utf8" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "DISTNAME" => "WWW-Sitemapper",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "WWW::Sitemapper",
  "PREREQ_PM" => {
    "DateTime" => 0,
    "DateTime::Duration" => 0,
    "Encode" => 0,
    "HTML::HeadParser" => "3.40",
    "HTTP::Message" => "6.0",
    "LWP" => "6.0",
    "Moose" => 0,
    "MooseX::MethodAttributes::Inheritable" => 0,
    "MooseX::Types" => 0,
    "MooseX::Types::Moose" => 0,
    "Storable" => 0,
    "Template" => 0,
    "URI" => 0,
    "WWW::Robot" => 0,
    "WWW::Sitemap::XML" => 0,
    "WWW::Sitemap::XML::URL" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.121160",
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



