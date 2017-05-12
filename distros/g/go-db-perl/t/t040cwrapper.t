#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use Test;
BEGIN { plan tests => 1, todo => [1] }   
use GO::TestHarness;
use GO::AppHandle;

# ----- REQUIREMENTS -----

# ------------------------

#n_tests(7);

#stmt_ok;
#exit 0;

my $files = shift @ARGV;
eval {
    my $apph = GO::AppHandle->connect(-files=>$files);
    #$apph->write_graph();
    my $node = $apph->get_term({acc=>3734});
    printf "node=$node\n";
    print $node->name;
    print join(",",  @{$node->synonym_list})."\n";
    ok(0);
};
if ($@) {
    ok(1);
}
