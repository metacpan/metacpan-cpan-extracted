use strict;
use warnings;
use 5.010;
use Test::More;
use Test::Warnings qw/ :report_warnings /;
use Encode;

use FindBin '$Bin';
use YAML::Tidy;

my $cfg = YAML::Tidy::Config->new( configfile => "$Bin/yamltidy" );
my $yt = YAML::Tidy->new( cfg => $cfg );
my $yaml = decode_utf8 <<'EOM';
blöck:   
 "seq" :
     - 1   
     - "true"
     - "3"
map:
     a:   &ONE 1   
     b  : *ONE
flow: [
        {
        "x":*ONE
        } ,
     ]  
EOM
my $exp = decode_utf8 <<'EOM';
---
blöck:
  seq :
  - 1
  - "true"
  - "3"
map:
  a: &ONE 1
  b  : *ONE
flow: [
    {
      x: *ONE
    } ,
  ]
EOM

my $tidied = $yt->tidy($yaml);

is $tidied, $exp, "Basic tidy test";

done_testing;
