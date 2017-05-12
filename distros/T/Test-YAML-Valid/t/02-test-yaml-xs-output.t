#!/usr/bin/perl
# 02-test-yaml-output.t

use strict;
use warnings;

use FindBin;
use File::Spec::Functions;

use Test::Builder::Tester;
use Test::More;
BEGIN {
    plan skip_all => 'YAML::XS required to test with YAML::XS'
      unless eval "require YAML::XS";
}
use Test::YAML::Valid qw(-XS);
plan tests => 3;

my $yaml =<<'YAML';
baz:
  - quux
  - quuuux
  - quuuuuux
  - car
  - cdr
foo: bar
YAML

my $bad_yaml =<<'BAD_YAML';
baz:
  - quux
  - quuuux
  - quuuuuux
  - car
  - cdr
foo::*)-> bar
BAD_YAML

## test yaml_string_ok ...

test_out("ok 1 - YAML string is ok");
test_out("ok 2");
test_out("not ok 3 - bad YAML string is bad");
test_out("not ok 4");
test_fail(4);
test_fail(4);
yaml_string_ok($yaml, 'YAML string is ok');
yaml_string_ok($yaml);
yaml_string_ok($bad_yaml, 'bad YAML string is bad');
yaml_string_ok($bad_yaml);

test_test("yaml_string_ok works");

## test yaml_file_ok ...

my $file = catfile($FindBin::Bin, "yaml", "basic.yml");
my $bad_file = catfile($FindBin::Bin, "yaml", "basic_bad.yml");

test_out("ok 1 - YAML file was ok");
test_out("ok 2 - $file contains valid YAML");
test_out("not ok 3 - bad YAML file was bad");
test_out("not ok 4 - $bad_file contains valid YAML");
test_fail(4);
test_fail(4);
yaml_file_ok($file, 'YAML file was ok');
yaml_file_ok($file);
yaml_file_ok($bad_file, 'bad YAML file was bad');
yaml_file_ok($bad_file);

test_test("yaml_file_ok works");

## test yaml_files_ok ...

my $dir = catfile($FindBin::Bin, "yaml", "all_valid", "*");
my $bad_dir = catfile($FindBin::Bin, "yaml", "*");

test_out("ok 1 - YAML files are all ok");
test_out("ok 2 - $dir contains valid YAML files");
test_fail(8);
test_out("not ok 3 - bad YAML files are not all ok");
test_err("#   Could not load file: $bad_file.");
test_fail(6);
test_out("not ok 4 - $bad_dir contains valid YAML files");
test_err("#   Could not load file: $bad_file.");
yaml_files_ok("$dir", 'YAML files are all ok');
yaml_files_ok("$dir");
yaml_files_ok("$bad_dir", 'bad YAML files are not all ok');
yaml_files_ok("$bad_dir");

test_test("yaml_files_ok works");
