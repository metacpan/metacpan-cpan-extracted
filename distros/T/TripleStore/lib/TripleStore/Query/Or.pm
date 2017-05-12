# -------------------------------------------------------------------------------------
# TripleStore::Query::Clause::Or
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: Or.pm,v 1.1.1.1 2003/01/13 18:20:40 jhiver Exp $
#
#    Description:
#
#      Boolean AND between Query objects.
#
# -------------------------------------------------------------------------------------
package TripleStore::Query::Or;
use strict;
use warnings;
use Carp;
our @ISA = qw /TripleStore::Query/;


##
# $class->new (@queries);
# -----------------------
# Constructs an object that represents a boolean AND
# between each query object in @queries.
##
sub new
{
    my $class = shift;
    $class    = ref $class || $class;
    my @args  = map { $_->isa ('TripleStore::Query::Or') ? ( $_->list_subqueries() ) : $_ } @_;
    my $self = bless \@args, $class;
}


##
# $self->list_subqueries();
# -------------------------
# Lists all the subqueries which are underneath that
# TripleStore::Query object.
##
sub list_subqueries
{
    my $self = shift;
    return @{$self};
}


##
# $self->list_clauses();
# ----------------------
# Lists all the clauses which are underneath that
# TripleStore::Query object. Order is not guaranteed.
##
sub list_clauses
{
    my $self = shift;
    return map { $_->list_clauses() } @{$self};
}


##
# $self->list_variables();
# ------------------------
# Lists all the variables which are underneath that
# TripleStore::Query object. Order is not guaranteed.
##
sub list_variables
{
    my $self = shift;
    my @duplicates = map { $_->list_variables() } @{$self};
    my %hash = map { ( 0 + $_ => $_ ) } @duplicates;
    return values %hash;
}


##
# $self->criterion_values();
# --------------------------
# Returns all the criterion values in the (subject, predicate, object)
# order. Returns an array in list context or an arrayref otherwise.
##
sub criterion_values
{
    my $self = shift;
    my @res  = map { $_->criterion_values() } @{$self};
    return wantarray ? @res : \@res;
}


1;


__END__
