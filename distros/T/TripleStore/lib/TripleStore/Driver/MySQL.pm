# -------------------------------------------------------------------------------------
# TripleStore::Driver::MySQL
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: MySQL.pm,v 1.1.1.1 2003/01/13 18:20:39 jhiver Exp $
#
#    Description:
#
#      MySQL driver
#
# -------------------------------------------------------------------------------------
package TripleStore::Driver::MySQL;
use strict;
use warnings;
use Carp;
use DBI;
use base qw /TripleStore::Driver::SQL/;


## TRANSACTION STUFF
sub tx_start
{
    # TODO
}


sub tx_stop
{
    # TODO
}


sub tx_abort
{
    # TODO
}


## INSERT
sub _prepared_sql_insert
{ 
    my $self = shift;
    return 'INSERT INTO TRIPLE_STORE SET S_T=?, S_N=?, P_T=?, P_N=?, O_T=?, O_N=?';
}


## UPDATE
sub _prepared_sql_update
{
    my $self = shift;
    my $set_sql = shift;
    my $where_sql = shift;
    return "UPDATE TRIPLE_STORE SET $set_sql WHERE $where_sql";
}


sub _prepared_sql_update_set
{
    my $self = shift;
    my $update = shift;
    my @res = ();
    if ($update->exists_subject())   { push @res, "S_T = ?, S_N = ?" };
    if ($update->exists_predicate()) { push @res, "P_T = ?, P_N = ?" };
    if ($update->exists_object())    { push @res, "O_T = ?, O_N = ?" };
    return join ', ', @res;
}


sub _prepared_sql_update_where
{
    my $self = shift;
    return $self->_prepared_sql_clause (@_);
}


## DELETE
sub _prepared_sql_delete
{
    my $self = shift;
    my $where_sql = shift;
    return "DELETE FROM TRIPLE_STORE WHERE $where_sql";
}


sub _prepared_sql_delete_where
{
    my $self = shift;
    return $self->_prepared_sql_clause (@_);
}


## DEPLOY
sub _prepared_sql_deploy
{
    my $self = shift;
    return join "\n", (
	'CREATE TABLE IF NOT EXISTS TRIPLE_STORE (',
	'    S_T   TEXT,',
	'    S_N   DOUBLE,',
	'    P_T   TEXT,',
	'    P_N   DOUBLE,',
	'    O_T   TEXT,',
	'    O_N   DOUBLE',
	')'
       );
}


## HELPER METHODS


sub _sql_symbol_triple_store   { 'TRIPLE_STORE' }
sub _sql_symbol_subject_text   { 'S_T' }
sub _sql_symbol_subject_num    { 'S_N' }
sub _sql_symbol_predicate_text { 'P_T' }
sub _sql_symbol_predicate_num  { 'P_N' }
sub _sql_symbol_object_text    { 'O_T' }
sub _sql_symbol_object_num     { 'O_N' }


sub select
{
    my $self = shift;
    $self->{Alias} = 'A';
    return $self->SUPER::select (@_);
}


sub _next_alias
{
    my $self = shift;
    return $self->{Alias}++;
}


sub _prepared_sql_clause
{
    my $class = shift->class;
    my $clause = shift;
    my @cols = ();
    my $criterion_class = 'TripleStore::Query::Criterion';
    
    if ($clause->subject()->isa ($criterion_class))
    {
	my $criterion = $clause->subject();
	my $operator  = $class->_sql_operator ($criterion->operator());
	if (defined $criterion->value())
	{
	    push @cols, $criterion->is_numeric_operator() ? "S_N $operator ?" : "S_T $operator ?";
	}
	else
	{
	    if    ($criterion->operator() eq 'eq') { push @cols, "S_T IS NULL"     }
	    elsif ($criterion->operator() eq '==') { push @cols, "S_N IS NULL"     }
	    elsif ($criterion->operator() eq 'ne') { push @cols, "S_T IS NOT NULL" }
	    elsif ($criterion->operator() eq '!=') { push @cols, "S_N IS NOT NULL" }
	    else { push @cols, $criterion->is_numeric_operator() ? "S_N $operator ?" : "S_T $operator ?" }
	}
    }
    
    if ($clause->predicate()->isa ($criterion_class))
    {
	my $criterion = $clause->predicate();
	my $operator  = $class->_sql_operator ($criterion->operator());
	if (defined $criterion->value())
	{
	    push @cols, $criterion->is_numeric_operator() ? "P_N $operator ?" : "P_T $operator ?";
	}
	else
	{
	    if    ($criterion->operator() eq 'eq') { push @cols, "P_T IS NULL"     }
	    elsif ($criterion->operator() eq '==') { push @cols, "P_N IS NULL"     }
	    elsif ($criterion->operator() eq 'ne') { push @cols, "P_T IS NOT NULL" }
	    elsif ($criterion->operator() eq '!=') { push @cols, "P_N IS NOT NULL" }
	    else { push @cols, $criterion->is_numeric_operator() ? "P_N $operator ?" : "P_T $operator ?" }
	}
    }
    
    if ($clause->object()->isa ($criterion_class))
    {
	my $criterion = $clause->[2];
	my $operator  = $class->_sql_operator ($criterion->operator());
	if (defined $criterion->value())
	{
	    push @cols, $criterion->is_numeric_operator() ? "O_N $operator ?" : "O_T $operator ?";
	}
	else
	{
	    if    ($criterion->operator() eq 'eq') { push @cols, "O_T IS NULL"     }
	    elsif ($criterion->operator() eq '==') { push @cols, "O_N IS NULL"     }
	    elsif ($criterion->operator() eq 'ne') { push @cols, "O_T IS NOT NULL" }
	    elsif ($criterion->operator() eq '!=') { push @cols, "O_N IS NOT NULL" }
	    else { push @cols, $criterion->is_numeric_operator() ? "O_N $operator ?" : "O_T $operator ?" }
	}
    }
    
    return join ' AND ', @cols;
}


1;


__END__
