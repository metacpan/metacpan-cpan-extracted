#!/usr/local/bin/perl -w

# All tests must be run from the software directory;
# make sure we are getting the modules from here:
use lib '.';
use strict;
use GO::TestHarness;
use Set::Scalar;

n_tests(6);

my $apph = get_readonly_apph();
stmt_ok;

# lets check we got stuff

my $t = $apph->get_term({name=>'endoplasmic reticulum'});
my $g = $apph->get_node_graph($t->acc, -1, {terms=>"shallow"});
my @terms = grep {$_->acc ne $t->acc} @{$g->get_all_nodes()};

$apph->filters({evcodes=>["!IEA"]});
my $al1 = $apph->get_all_associations($t);
my $set_all = Set::Scalar->new;
map {$set_all->insert($_->id)} @$al1;

my $n = scalar(@$al1);
printf "%s: all assocs:  %d \n", $t->acc, $n;
my $al2 = $apph->get_direct_associations($t);
my $set_d = Set::Scalar->new;
map {$set_d->insert($_->id)} @$al2;
my $n_d = scalar(@$al2);
printf "%s: direct assocs: %d\n", $t->acc, $n_d;
stmt_check(scalar(@$al2) < scalar(@$al1));

my $n2=0;
my $set_children = Set::Scalar->new;
foreach my $t (@terms) {
    my $al = $apph->get_direct_associations($t);
    $n2+= scalar(@$al);

    map {$set_children->insert($_->id)} @$al;
}

my $set2 = $set_d->union($set_children);

stmt_check(! $set_all->difference($set2)->members);

my $al4 = $apph->get_all_associations({name=>"endoplasmic reticulum"},
				      {evcodes=>["ISS"]});
my $al5 = $apph->get_all_associations({name=>"endoplasmic reticulum"},
				      {evcodes=>["IEA"]});
my $al6 = $apph->get_all_associations({name=>"endoplasmic reticulum"},
				      {evcodes=>["IEA", "ISS"]});

printf "%d %d %d\n",
  scalar(@$al4),
  scalar(@$al5),
  scalar(@$al6),
  ;
stmt_check(scalar(@$al4) + scalar(@$al5) >= scalar(@$al6));

# now check filters
$apph->filters({evcodes=>["!IEA"]});
$t = $apph->get_term({name=>"endoplasmic reticulum"}, "shallow");
my $al7 = $t->association_list;
printf "term assocs with filter !IEA =%s\n", scalar(@$al7);
$apph->filters({evcodes=>["IEA"]});
$t = $apph->get_term({name=>"endoplasmic reticulum"}, "shallow");
my $al8 = $t->association_list;
printf "term assocs with filter IEA =%s\n", scalar(@$al8);

$apph->filters({evcodes=>[]});
my $al9 = $apph->get_direct_associations($t);

#simple pass-through test (test if AppHandle API/schema change fails next 2 calls)
$apph->get_qualifiers($al9);
$apph->get_assigned_by($al9);

printf "checking set IEA union !IEA = total direct associations...\n";
my %set = ();
map {$set{$_->id} = 1}@$al7;
map {$set{$_->id} = 1}@$al8;
printf "set size = %d\n", scalar(keys %set);
stmt_check(scalar(keys %set)  == scalar(@$al9));

$apph->disconnect;
stmt_ok;

