#!/usr/bin/perl - for emacs :)
package main;
use Test::More;
use strict;
use warnings;
use lib qw /lib/;


BEGIN
{
    my $info_file = 't/driver.nfo';
    $::DRIVER = eval {
	-e $info_file or die "$info_file does not exist";
	open FP, "<$info_file" or die "Cannot read-open $info_file";
	my $data = join '', <FP>;
	close FP;
	
	my $VAR1 = undef;
	eval "$data";
	die "Cannot evaluate data: $@" if (defined $@ and $@);
	
	return $VAR1;
    };
    
    (defined $@ and $@) ?
        plan skip_all => $@ :
	plan 'no_plan' ;
}


main();


sub main
{    
    use_ok ('TripleStore');
    $::DB = new TripleStore ($::DRIVER);
    
    # starts a transaction
    eval { $::DB->tx_start() };
    is ($@, '', 'tx_start() - does not die');

    # aborts the transaction
    eval { $::DB->tx_abort() };
    is ($@, '', 'tx_abort() - does not die');
    
    # starts a transaction
    eval { $::DB->tx_start() };
    is ($@, '', 'tx_start() - does not die');

    # stops the transaction
    eval { $::DB->tx_stop() };
    is ($@, '', 'tx_stop() - does not die');
    
    # inserts a bunch of triples
    eval { insert_some_triples() };
    is ($@, '', 'inserts some triples');

    # tests boolean operators
    boolean_operators();
    
    # performs some queries...
    query_1();
    query_2();
    
    # cleans all the mess up
    eval { $::DB->delete ( $::DB->clause ( [ qw /like %/ ], undef, undef ) ) };
    is ($@, '', 'cleanup');
}


sub boolean_operators
{
    my $x = $::DB->var();
    my $y = $::DB->var();
    
    ok ($x->isa ('TripleStore::Query::Variable'), '$x is a variable');
    ok ($y->isa ('TripleStore::Query::Variable'), '$y is a variable');
    
    my $c1 = $::DB->clause ($x, 'name', $y);
    my $c2 = $::DB->clause ($x, 'creator', 'jhiver');
    
    ok ($c1->isa ('TripleStore::Query::Clause'), '$c1 is a clause');
    ok ($c2->isa ('TripleStore::Query::Clause'), '$c2 is a clause');
    
    my $c3 = $c1 & $c2;
    ok ($c3->isa ('TripleStore::Query::And'), '$c3 is a clause');
}



# gets all the software which has been created
# by jhiver, and sorts them by alphabetical
# order
sub query_1
{
    my $x = $::DB->var();
    my $y = $::DB->var();
    my $query = $::DB->select (
	$x, $y,
	$::DB->clause ($x, 'name', $y) &
	$::DB->clause ($x, 'creator', 'jhiver'),
	$::DB->sort_str_asc ($y),
       );
    
    my $result;
    $result = $query->next();
    is ($result->[0], '2', 'query_1 ~1');
    is ($result->[1], 'mkdoc', 'query_1 ~2');
    
    $result = $query->next();
    is ($result->[0], '3', 'query_1 ~3');
    is ($result->[1], 'petal', 'query_1 ~4');
    
    $result = $query->next();
    is ($result, undef, 'query_1 ~4');
}


# gets all the software which has been created
# by jhiver, and sorts them by alphabetical
# order
sub query_2
{
    my $x = $::DB->var();
    my $y = $::DB->var();
    my $query = $::DB->select (
	$x, $y,
	$::DB->clause ($x, 'name', $y) &
	$::DB->clause ($x, 'creator', 'jhiver') &
	$::DB->clause ($x, 'contributor', 'bruno' ),
	$::DB->sort_str_asc ($y),
       );
    
    my $result;
    $result = $query->next();
    is ($result->[0], '2', 'query_2 ~1');
    is ($result->[1], 'mkdoc', 'query_2 ~2');
    
    $result = $query->next();
    is ($result, undef, 'query_1 ~4');
}


sub insert_some_triples
{
    $::DB->insert ('1', 'name', 'panorama tools');
    $::DB->insert ('1', 'creator', 'bruno');
    $::DB->insert ('1', 'contributor', 'jhiver');
    
    $::DB->insert ('2', 'name', 'mkdoc');
    $::DB->insert ('2', 'creator', 'jhiver');
    $::DB->insert ('2', 'contributor', 'bruno');
    $::DB->insert ('2', 'contributor', 'chris');
    $::DB->insert ('2', 'contributor', 'patrick');
    $::DB->insert ('2', 'contributor', 'steve');
    
    $::DB->insert ('3', 'name', 'petal');
    $::DB->insert ('3', 'creator', 'jhiver');
    $::DB->insert ('3', 'contributor', 'william');
}


1;


__END__
