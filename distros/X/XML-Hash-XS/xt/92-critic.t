# test for recommendations from "Perl Best Practices"

use strict;
use warnings;
use Test::More;

eval { use Test::Perl::Critic };
plan skip_all => 'Test::Perl::Critic required' if $@;

# check only new code
my @dirs = qw( lib );
my @files = glob('t/*.t xt/*.t');

push @files, Perl::Critic::Utils::all_perl_files(@dirs);

plan tests => scalar(@files);
critic_ok($_) foreach @files;
