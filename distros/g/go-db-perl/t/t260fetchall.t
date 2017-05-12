#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:

use lib '.';
use strict;
use Test;
BEGIN { plan tests => 2 }
use GO::TestHarness;
set_n_tests(2);

use GO::AppHandle;

my $apph = get_readonly_apph();

my $tl = $apph->get_terms;

stmt_note(scalar(@$tl));
stmt_check(scalar(@$tl) > 7000);

# old versions of the db had accs with no name
@$tl = grep {$_->acc} @$tl;
my $g = $apph->get_graph_by_terms($tl);
#$g->to_text_output;
stmt_note(scalar @$tl);
stmt_note($g->node_count);
stmt_check(scalar(@$tl) == $g->node_count);
