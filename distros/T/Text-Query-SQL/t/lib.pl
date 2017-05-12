use strict;

package main;

use Test;
use DBI;
use Carp;

use Text::Query;

require "t/$::db_type.pl";

my($db);

sub builddb {
    my($schema) = t1_schema();

    if(!$schema) {
	print STDERR "DBI_DSN not set for $::db_type ";
	plan test => 0;
	exit(0);
    }
    $db = DBI->connect(undef, undef, undef, dbi_args());
    if(!$db) {
	print STDERR "cannot connect $DBI::errstr (check DBI_DSN, DBI_USER and DBI_PASS) ";
	plan test => 0;
	exit(0);
    }

    if(!$db->do($schema)) {
	print STDERR "cannot execute $schema $DBI::errstr (check DBI_DSN, DBI_USER and DBI_PASS) ";
	plan test => 0;
	exit(0);
    }
    my($i);
    for($i = 0; $i < 200; $i++) {
	my($sql) = "insert into t1 values ('$i', '" . ($i - 1) . " " . $i . " " . ($i + 1) . "')";
	$db->do($sql) or croak("cannot execute $sql : $DBI::errstr");
    }

    my($postamble) = t1_postamble();
    if($postamble) {
	$db->do($postamble) or croak("cannot execute $postamble : $DBI::errstr");
    }
}

sub destroydb {
    my($sql) = t1_drop();

    $db->do($sql) or croak("cannot execute $sql : $DBI::errstr");
}

builddb();

plan test => 14;

#
# Simple search
#
{
    my(@rows);
    my($question);
    my($builder) = builder();
    my($rel) = relevance_info();
    my($query) = Text::Query->new('blurk',
				  -parse => 'Text::Query::ParseSimple',
				  -build => $builder,
				  -solve => 'Text::Query::SolveSQL',
				  -fields_searched => 'field2',
				  -select => "select $rel->{'select'}field1 from t1 where __WHERE__ order by $rel->{'order'}field1 asc",
				  );

    $question = "20";
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')},$rows[1]->{upperlower('field1')},$rows[2]->{upperlower('field1')}\n";
    ok(@rows == 3 &&
       $rows[0]->{upperlower('field1')} eq '19' &&
       $rows[1]->{upperlower('field1')} eq '20' &&
       $rows[2]->{upperlower('field1')} eq '21'
       , 1, $query->matchstring());

    $question = "20 -21";
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')}\n";
    ok(@rows == 1 &&
       $rows[0]->{upperlower('field1')} eq '19', 1, $query->matchstring());

    $question = "20 +21";
    $query->prepare($question);
    @rows = $query->match($db);
    if($rel->{'field'}) {
	print scalar(@rows) . "values => $rows[0]->{upperlower('field1')},$rows[1]->{upperlower('field1')},$rows[2]->{upperlower('field1')}\n";
	print scalar(@rows) . "relevance => $rows[0]->{upperlower($rel->{'field'})},$rows[1]->{upperlower($rel->{'field'})},$rows[2]->{upperlower($rel->{'field'})}\n";
	ok(@rows == 3 &&
	   $rows[0]->{upperlower('field1')} eq '20' &&
	   $rows[1]->{upperlower('field1')} eq '21' &&
	   $rows[2]->{upperlower('field1')} eq '22'
	   , 1, $query->matchstring());
    } else {
	print scalar(@rows) . " => $rows[0]->{upperlower('field1')},$rows[1]->{upperlower('field1')}\n";
	ok(@rows == 2 &&
	   $rows[0]->{upperlower('field1')} eq '20', 1, $query->matchstring());
    }
}

#
# Advanced search
#
{
    my(@rows);
    my($question);
    my($builder) = builder();
    my($query) = Text::Query->new('blurk',
				  -parse => 'Text::Query::ParseAdvanced',
				  -build => $builder,
				  -solve => 'Text::Query::SolveSQL',
				  -fields_searched => 'field2',
				  -select => 'select field1 from t1 where __WHERE__ order by field1 asc',
				  );

    $question = "20";
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')}\n";
    ok(@rows == 3 &&
       $rows[0]->{upperlower('field1')} eq '19', 1, $query->matchstring());

    $question = "21 and 20";
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')},$rows[1]->{upperlower('field1')}\n";
    ok(@rows == 2 &&
       $rows[0]->{upperlower('field1')} eq '20' &&
       $rows[1]->{upperlower('field1')} eq '21'
       , 1, $query->matchstring());

    $question = "21 or 20";
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')},$rows[1]->{upperlower('field1')}...\n";
    ok(@rows == 4 &&
       $rows[0]->{upperlower('field1')} eq '19' &&
       $rows[1]->{upperlower('field1')} eq '20' &&
       $rows[2]->{upperlower('field1')} eq '21' &&
       $rows[3]->{upperlower('field1')} eq '22'
       , 1, $query->matchstring());

    $question = "21 or 30 and 32";
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')},$rows[1]->{upperlower('field1')},$rows[2]->{upperlower('field1')},$rows[3]->{upperlower('field1')}\n";
    ok(@rows == 4 &&
       $rows[0]->{upperlower('field1')} eq '20' &&
       $rows[1]->{upperlower('field1')} eq '21' &&
       $rows[2]->{upperlower('field1')} eq '22' &&
       $rows[3]->{upperlower('field1')} eq '31'
       , 1, $query->matchstring());

    $question = "(21 or 30) and 19";
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')}\n";
    ok(@rows == 1 &&
       $rows[0]->{upperlower('field1')} eq '20'
       , 1, $query->matchstring());


    $question = "20 21";
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')},$rows[1]->{upperlower('field1')}\n";
    ok(@rows == 2 &&
       $rows[0]->{upperlower('field1')} eq '20' &&
       $rows[1]->{upperlower('field1')} eq '21'
       , 1, $query->matchstring());
    
    $question = "(20) (21)";
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')},$rows[1]->{upperlower('field1')}\n";
    ok(@rows == 2 &&
       $rows[0]->{upperlower('field1')} eq '20' &&
       $rows[1]->{upperlower('field1')} eq '21'
       , 1, $query->matchstring());

    $question = "20 and not 21";
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')}\n";
    ok(@rows == 1 &&
       $rows[0]->{upperlower('field1')} eq '19'
       , 1, $query->matchstring());

    $question = "20 near 21";
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')},$rows[1]->{upperlower('field1')}\n";
    ok(@rows == 2 &&
       $rows[0]->{upperlower('field1')} eq '20' &&
       $rows[1]->{upperlower('field1')} eq '21'
       , 1, $query->matchstring());

    $question = 'field2: ( 20 and 21 ) or field1: 100 or "field2:"';
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . " => $rows[0]->{upperlower('field1')},$rows[1]->{upperlower('field1')},$rows[2]->{upperlower('field1')}\n";
    ok(@rows == 3 &&
       $rows[0]->{upperlower('field1')} eq '100' &&
       $rows[1]->{upperlower('field1')} eq '20' &&
       $rows[2]->{upperlower('field1')} eq '21'
       , 1, $query->matchstring());
    
    $question = "21 or 30 and 32";
    $query->prepare($question);
    @rows = $query->match($db);

    $question = 'field2: ( 20 and 21 or field1: 21 ) or field1: 100 or "field2:" and 30 near 40';
    $query->prepare($question);
    @rows = $query->match($db);
    print scalar(@rows) . "\n";
    ok(@rows > 1, 1, $query->matchstring());
}

destroydb();

# Local Variables: ***
# mode: perl ***
# End: ***
