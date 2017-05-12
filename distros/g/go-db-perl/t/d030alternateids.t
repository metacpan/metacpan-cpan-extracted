#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

n_tests(6);

use GO::Parser;

# Get args

create_test_database("go_alttest");
my $apph = getapph();

stmt_ok;
my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);
stmt_ok;
$parser->parse ("./t/data/function-withaltid.dat");

stmt_ok;

# lets check we got stuff

my $t = $apph->get_term({acc=>15204});
stmt_note($t->name);
stmt_check($t->name eq "urea transporter");
$t = $apph->get_term({acc=>15287});
stmt_check(!$t);

$apph->disconnect;
destroy_test_database();
stmt_ok;
