######################################################################
# Test suite for YAML::Logic
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use YAML::Syck qw(Load Dump);
use Test::More qw(no_plan);
use Data::Dumper;
use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init($DEBUG);

my $path = "Logic.pm";
$path = "../$path" if ! -f $path;

SKIP: {
    eval "require Pod::Snippets";
    skip "Pod::Snippets not installed", 5 if $@;

    my $snippets = Pod::Snippets->load($path, -markup => "test");

    for my $snip ( $snippets->named("yaml")->as_data() ) {
        DEBUG "Testing snip: $snip";
        eval { Load $snip; };
        is($@, "", "snip") or die $snip;
    }
}
