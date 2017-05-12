#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use GO::Admin;
use Test;
BEGIN { plan tests => 4, todo => [] }
set_n_tests(4);

use GO::Parser;

 # Get args

create_test_database("go_refg_test");
my $apph = getapph() || die;

my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);

$parser->set_type('go_assoc');
$parser->handler->optimize_by_dtype('go_assoc');
$parser->acc2name_h($apph->acc2name_h);
$parser->cache_errors;
$parser->parse("./t/data/mini-fb-assocs.fb");
my @errs = $parser->errlist;
print $_->sxpr foreach @errs;

$parser->parse ("./t/data/gene_association-ache.all");
ok(1);
ok(!system('wget -O refg_id_list.txt --passive-ftp ftp://ftp.informatics.jax.org/pub/curatorwork/GODB/refg_id_list.txt'));

my $args = get_command_line_connect_args();
print "args=$args\n";
ok(!system("load-refg-set-full.pl $args refg_id_list.txt"));


$apph->disconnect;
#destroy_test_database();
ok(1);
