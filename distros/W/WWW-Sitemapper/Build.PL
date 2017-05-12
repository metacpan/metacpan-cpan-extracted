
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
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
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Create text, html and xml sitemap by scanning a web site.",
  "dist_author" => [
    "Alex J. G. Burzy\305\204ski <ajgb\@cpan.org>"
  ],
  "dist_name" => "WWW-Sitemapper",
  "dist_version" => "1.121160",
  "license" => "perl",
  "module_name" => "WWW::Sitemapper",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
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
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
