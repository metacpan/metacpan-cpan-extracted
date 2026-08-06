# test for recommendations from "Perl Best Practices"

use strict;
use warnings;
use Test::More;

eval {
    require Test::Perl::Critic;
    Test::Perl::Critic->import();
    require Perl::Critic::Utils;
    1;
} or plan skip_all => 'Test::Perl::Critic required';

# check only new code
my @dirs = qw( lib );
my @files = glob('t/*.t xt/*.t');

push @files, Perl::Critic::Utils::all_perl_files(@dirs);

plan tests => scalar(@files);
critic_ok($_) foreach @files;
