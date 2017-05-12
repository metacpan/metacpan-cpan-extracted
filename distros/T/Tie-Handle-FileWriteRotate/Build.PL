
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "Module::Build" => "0.3601"
  },
  "configure_requires" => {
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "Filehandle tie to write to autorotated file with File::Write::Rotate",
  "dist_author" => [
    "Steven Haryanto <stevenharyanto\@gmail.com>"
  ],
  "dist_name" => "Tie-Handle-FileWriteRotate",
  "dist_version" => "0.02",
  "license" => "perl",
  "module_name" => "Tie::Handle::FileWriteRotate",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "File::Write::Rotate" => "0.01",
    "perl" => "5.010001"
  },
  "script_files" => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
