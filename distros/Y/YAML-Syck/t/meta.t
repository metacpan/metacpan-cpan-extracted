use strict;
use warnings;
use Test::More tests => 1;

use FindBin;
use YAML::Syck;

my $yaml = YAML::Syck::LoadFile( $FindBin::Bin . '/../META.yml' );
is( $yaml->{'version'}, $YAML::Syck::VERSION, "META.yml file is correct - To regenerate, run: 'make purge; perl Makefile.pl'" );
