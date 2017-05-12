
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601",
    "Test::More" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Scripting www.ruten.com.tw",
  "dist_author" => [
    "Kang-min Liu <gugod\@gugod.org>"
  ],
  "dist_name" => "WWW-Ruten",
  "dist_version" => "0.03",
  "license" => "mit",
  "module_name" => "WWW::Ruten",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Encode" => 0,
    "HTML::Selector::XPath" => 0,
    "HTML::TreeBuilder::XPath" => 0,
    "WWW::Mechanize" => "1.66",
    "perl" => "5.008",
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
