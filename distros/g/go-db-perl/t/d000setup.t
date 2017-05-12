#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;

n_tests(20);


use GO::Parser;
use GO::SqlWrapper qw(:all);

create_test_database("go_mini");
# Get args

my $apph = getapph();
my $dbh = $apph->dbh;

stmt_ok;
my $parser = new GO::Parser ({handler=>'db'});
$parser->xslt('oboxml_to_godb_prestore');
$parser->handler->apph($apph);
$parser->handler->optimize_by_dtype('go_ont');
stmt_ok;
use Data::Dumper;
unless ($ENV{NO_REBUILD_GO_TEST_DATABASE}) {
    $parser->parse ("./t/data/test-nucleolar.ontology");
    $parser->parse ("./t/data/test-nucleolar.defs");
}
$parser->show_messages;
stmt_ok;

$apph->refresh;

# lets check we got stuff

stmt_check($apph->acc2name_h->{'GO:0008150'} eq 'biological_process');

my $t = $apph->get_term({acc=>8151});
stmt_check($t);
stmt_note("got term ".$t->name."\n");

$t = $apph->get_term({name=>"nuclear speck"});
stmt_check(@{$t->synonym_list} == 4);
stmt_check(grep {$_ eq 'nuclear speckle'} @{$t->synonym_list});

# check search works
my $tl = $apph->get_terms({search=>"nucleolar*"});
stmt_note(scalar(@$tl)." terms matched:");
stmt_check(scalar(@$tl) == 10);

# check synonym retrieval/constraints work
$t = $apph->get_term({synonym=>"nuclear speckle"});
stmt_note(@{$t->synonym_list});
stmt_check($t->has_synonym("speckle domain"));

# check definitions are stored/loaded ok
$t = $apph->get_term({acc=>9302});
stmt_note("got term ".$t->name."\n");
stmt_check($t->name eq 'snoRNA transcription');
stmt_check($t->type eq 'biological_process');
stmt_note("definition: ".$t->definition."\n");
stmt_check($t->definition =~ / small nucleolar RNA /);
stmt_note('comment: '.$t->comment);
stmt_check($t->comment =~ /test comment/);
stmt_note('comment ok');
my $defrefs = $t->definition_dbxref_list;
my @r = sort map {$_->as_str} @$defrefs;
stmt_note("@r");
stmt_check("@r" eq "GO:curators testdb:001");

my $g = $apph->get_graph(7575);
$t = $g->focus_nodes->[0];
stmt_note("got term ".$t->name);
stmt_check($t->name eq 'nucleolar size increase');

stmt_note("getting parents for term with acc ".$t->acc);
my @p = @{$g->get_parent_terms($t->acc)};
map{stmt_note($_->acc)} @p;
stmt_check(grep {$_->acc eq 'GO:0008371'} @p);

# check relationships

my $rl = $apph->get_relationships({acc2=>'GO:0007575'});
stmt_note($rl->[0]->type);
use Data::Dumper;
print Dumper $rl;
stmt_check($rl->[0]->type eq "is_a");
$rl = $apph->get_relationships({acc2=>'GO:0008150'});
stmt_note($rl->[0]->type); 
stmt_check($rl->[0]->type eq "part_of");                                                 
# check audit stuff
my $hl = select_hashlist($dbh,
			 "source_audit");

my $ok = 1;
foreach my $h (@$hl) {
    if (!$h->{source_mtime}) {
	$ok = 0;
    }
    print "$h->{source_path} $h->{source_mtime}\n";
}
stmt_check($ok);
$apph->disconnect;
stmt_ok;
