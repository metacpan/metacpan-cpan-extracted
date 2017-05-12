# -------------------------------------------------------------------------------------
# TripleStore::Query
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: Query.pm,v 1.1.1.1 2003/01/13 18:20:39 jhiver Exp $
#
#    Description:
#
# -------------------------------------------------------------------------------------
package TripleStore::Query;
use strict;
use warnings;
use Carp;

use TripleStore::Query::Variable;
use TripleStore::Query::Criterion;
use TripleStore::Query::Clause;
use TripleStore::Query::And;
use TripleStore::Query::Or;
use TripleStore::Query::Limit;
use TripleStore::Query::Sort;
use TripleStore::Query::Sort::NumericAscending;
use TripleStore::Query::Sort::NumericDescending;
use TripleStore::Query::Sort::StringAscending;
use TripleStore::Query::Sort::StringDescending;

use base qw /TripleStore::Mixin::Class
	     TripleStore::Mixin::Unimplemented/;


use overload (
    '*'  => \&_boolean_and,
    '+'  => \&_boolean_or,
    '&'  => \&_boolean_and,
    '|'  => \&_boolean_or,
    '""' => sub { return shift() },
   );


##
# $self->_boolean_and();
# ----------------------
# Returns a boolean AND of the queries.
##
sub _boolean_and
{
    my $self = shift;
    return new TripleStore::Query::And ($self, map { ref $_ ? $_ : () } @_);
}


##
# $self->_boolean_or();
# ----------------------
# Returns a boolean OR of the queries.
##
sub _boolean_or
{
    my $self = shift;
    return new TripleStore::Query::Or ($self, map { ref $_ ? $_ : () } @_);
}


##
# $self->list_subqueries();
# -------------------------
# Lists all the subqueries which are underneath that
# TripleStore::Query object.
##
sub list_subqueries
{
    my $class = shift->class;
    return $class->_unimplemented();
}


##
# $self->list_clauses();
# ----------------------
# Lists all the clauses which are underneath that
# TripleStore::Query object.
##
sub list_clauses
{
    my $class = shift->class;
    return $class->_unimplemented();
}


##
# $self->list_variables();
# ------------------------
# Lists all the variables which are underneath that
# TripleStore::Query object.
##
sub list_variables
{
    my $class = shift->class;
    return $class->_unimplemented();
}


1;


__END__
