#!/usr/bin/env perl
use strict;
use warnings;
use 5.020;
use Data::Dumper;
use YAML::PP::Ref;

#use YAML::PP::Ref::Parser;
#my $ypr = YAML::PP->new( parser => YAML::PP::Ref::Parser->new );

my $ypr = YAML::PP::Ref->new;

my $yaml = <<'EOM';
---
foo:
- bar
- boo
[23]: 42
EOM
my $data = $ypr->load_string($yaml);
warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$data], ['data']);
