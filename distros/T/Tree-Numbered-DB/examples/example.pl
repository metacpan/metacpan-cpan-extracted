#! /usr/bin/perl -w

# This script is one of the test scripts I used during development of this 
# module. It shows basic tree construction and some fiels juggling.
#
# To use it, create a table using the following SQL:
#
# create table try2 (num int auto_increment primary key, 
# 		     pr int not null, 
#		     url varchar(80),
#                    rating float);

use strict;
use version '0.05';

use Tree::Numbered::DB;

use Data::Dumper;
use DBI;

use Test::More tests => 11;

sub cmp_tree {
    my ($t1, $t2) = @_;
    return 0 unless (UNIVERSAL::isa($t1, 'Tree::Numbered::DB') && 
		     UNIVERSAL::isa($t2, 'Tree::Numbered::DB'));
    while (my $nd = $t1->nextNode) {
	return 0 unless cmp_tree($nd, $t2->nextNode) ;
    }
    my @fields1 = values %{$t1->getFields};
    my @fields2 = values %{$t2->getFields};
    return eq_set(\@fields1, \@fields2);
}

# Change this to suit your system (this is not *my* password, whadya think?
my $dbh = DBI->connect('DBI:someGreatDBD:test', 'u_r_a', 'loser');

my $tree = Tree::Numbered::DB->new(source => $dbh, source_name => 'try2',
				   serial_col => 'num', parent_col => 'pr',
				   URL_col => 'url', URL => 'www.stupid.com');
isa_ok ($tree, 'Tree::Numbered::DB', "new tree");

my (@fields, @wantfields);
@wantfields = ('URL');
@fields = $tree->getFieldNames;

ok (eq_set(\@wantfields, \@fields), 'fields as requested');
is ($tree->getURL, 'www.stupid.com', 'assignment to field');

my $child = $tree->append(URL => 'www.stupid.com/ariel_sharon.html');
isa_ok ($tree, 'Tree::Numbered::DB', "new child");

@fields = $child->getFieldNames;
ok (eq_set(\@wantfields, \@fields), 'fields as requested in child');
is ($tree->getURL, 'www.stupid.com', 'assignment to field in child');

ok ($tree->setURL('www.stupid.com/the_likud_party.html', "setURL"), 'setURL');

$tree->allProcess(sub{my $s=shift;$s->addField('Rating','2.5','rating');});
is ($tree->getRating, '2.5', "root got new field right");
is ($child->getRating, '2.5', "child got new field right");

# Check read:
my $tree2 = Tree::Numbered::DB->read('try2', $dbh, {serial_col => 'num', 
						    parent_col => 'pr', 
						    URL_col => 'url', 
						    Rating_col => 'rating'}
				     );
isa_ok ($tree2, 'Tree::Numbered::DB', "new tree from read");
my $ok = cmp_tree($tree, $tree2);
ok ($ok, 'trees are the same');

# For more data:
# use Data::Dumper;
# print Dumper($tree, $tree2);
