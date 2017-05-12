#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

# REQUIREMENTS
#
# check that the path table - population and querying - works
#
# also check gpc while we are here

n_tests(2);


use GO::Parser;
use Data::Dumper;
 # Get args

create_test_database("go_path");
my $apph = getapph();

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

stmt_note('loading assocs');
$parser->set_type('go_assoc');
$parser->handler->optimize_by_dtype('go_assoc');
$parser->acc2name_h($apph->acc2name_h);
$parser->cache_errors;
$parser->parse("./t/data/gene_assoc-with-quals.mgi");
my @errs = $parser->errlist;
print $_->sxpr foreach @errs;
stmt_note(scalar @errs);
stmt_check(@errs==0);

my $assocs = $apph->get_associations({acc=>"GO:0004842"});
my $ok = 0;
foreach my $assoc (@$assocs) {
    if ($assoc->is_not) {
        my @qs = map {$_->acc} @{$assoc->qualifier_list};
        if ((grep {$_ eq 'not'} @qs) && (grep {$_ eq 'contributes_to'} @qs)) {
            $ok = 1;
        }
        foreach (@{$assoc->qualifier_list}) {
            printf "Q:%s\n",$_->acc;
        }
    }
}

stmt_check($ok);
