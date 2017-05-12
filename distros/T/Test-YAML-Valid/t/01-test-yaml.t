#!/usr/bin/perl
# 01-test-yaml.t 
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;

use FindBin;
use File::Spec::Functions;

use Test::More tests => 7;
use Test::YAML::Valid;

my $yaml =<<'YAML';
baz:
  - quux
  - quuuux
  - quuuuuux
  - car
  - cdr
foo: bar
YAML

yaml_string_ok($yaml, 'YAML string is ok');
yaml_string_ok($yaml);

my $file = catfile($FindBin::Bin, "yaml", "basic.yml");
yaml_file_ok($file, 'file was OK');
yaml_file_ok($file);

my $dir = catfile($FindBin::Bin, "yaml", "all_valid", '*');

yaml_files_ok($dir, 'files are all OK');
yaml_files_ok($dir);

my $numbers = catfile($FindBin::Bin, "yaml", "numbers", '*');
yaml_files_ok($numbers);
