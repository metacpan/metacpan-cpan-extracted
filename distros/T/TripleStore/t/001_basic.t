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
    local $::DB = new TripleStore ($::DRIVER);
    
    # insert test
    {
	eval { $::DB->insert ('adam', 'shirt', 'green') };
	is ($@, '', 'insert() - does not die');
    
	my $dbh = $::DB->driver()->dbh();
	my $sth = $dbh->prepare ("SELECT * FROM TRIPLE_STORE WHERE S_T='adam'");
	$sth->execute();
	ok ($sth->fetchrow_arrayref, 'insert() - record inserted');
    }
    
    # update test
    {
	use_ok ('TripleStore::Update');
	use_ok ('TripleStore::Query::Criterion');
	use_ok ('TripleStore::Query::Clause');
	
	# make adam's shirt blue
	my $update = { object => 'blue' };
	my $clause = $::DB->clause ('adam', 'shirt', undef);
	eval { $::DB->update ($update, $clause) };
	
	is ($@, '', 'update() - does not die');
	my $dbh = $::DB->driver()->dbh();
	my $sth = $dbh->prepare ("SELECT * FROM TRIPLE_STORE WHERE S_T='adam' AND P_T='shirt' AND O_T='blue'");
	$sth->execute();
	ok ($sth->fetchrow_arrayref, 'update() - record updated');
    }

    # delete test
    {
	use_ok ('TripleStore::Query::Clause');
	use_ok ('TripleStore::Query::Criterion');
	my $clause = $::DB->clause ('adam', undef, undef);
	eval { $::DB->delete ($clause) };
	is ($@, '', 'delete() - does not die');
	
	my $dbh = $::DB->driver()->dbh();
	my $sth = $dbh->prepare ("SELECT * FROM TRIPLE_STORE WHERE S_T='adam'");
	$sth->execute();
	ok (!$sth->fetchrow_arrayref, 'delete() - record deleted');
    }
}


1;


__END__
