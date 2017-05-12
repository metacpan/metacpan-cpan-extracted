# -------------------------------------------------------------------------------------
# TripleStore::Query::Clause
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: Clause.pm,v 1.1.1.1 2003/01/13 18:20:40 jhiver Exp $
#
#    Description:
#
#       A clause is an object that describes triple properties.
#
#       For example let's say that you want all the triples with the
#       following constraints:
#
#       object <no constraint>
#       predicate equals 'first_name'
#       object contains 'bruno'
#
#       Then you would need to do the following:
#
#       my $x = new Triple::Store::Query::Variable(); # no constraints
#       my $firstName = new Triple::Store::Query::Criterion ('firstName');
#       my $containsBruno = new Triple::Store::Query::Criterion ('contains', 'bruno');
#       my $clause = new TripleStore::Query::Clause ($x, $firstName, $containsBruno);
#
# -------------------------------------------------------------------------------------
package TripleStore::Query::Clause;
use strict;
use warnings;
use Carp;
use TripleStore::Query::Criterion;
our @ISA = qw /TripleStore::Query/;

##
# $class->new ($subject_element, $predicate_element, $object_element);
# --------------------------------------------------------------------
# Constructs a new clause. Each element should be either a
# Triple::Store::Query::Criterion object or a Triple::Store::Query::Criterion
# object.
##
sub new
{
    my $class = shift;
    $class = ref $class || $class;
    return bless { array => \@_ }, $class;
}


##
# $self->subject();
# -----------------
# Returns this clause's subject, which might be either a variable
# or a criterion.
##
sub subject
{
    my $self = shift;
    return $self->{array}->[0];
}


##
# $self->predicate();
# -------------------
# Returns this clause's predicate, which might be either a variable
# or a criterion.
##
sub predicate
{
    my $self = shift;
    return $self->{array}->[1];
}


##
# $self->object();
# ----------------
# Returns this clause's object, which might be either a variable
# or a criterion.
##
sub object
{
    my $self = shift;
    return $self->{array}->[2];
}


##
# $self->list_clauses();
# ----------------------
# Lists all the clauses which are underneath that
# TripleStore::Query object.
##
sub list_clauses
{
    my $self = shift;
    return ($self);
}


##
# $self->list_variables();
# ------------------------
# Lists all the variables which are underneath that
# TripleStore::Query object.
##
sub list_variables
{
    my $self = shift;
    my @elements = @{$self->{array}};
    return map { $_->isa ('TripleStore::Query::Variable') ? $_ : () } @elements;
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
    my @res  = map {
	$_->isa ('TripleStore::Query::Criterion') ? $_->value() : ()
    } @{$self->{array}};
    return wantarray ? @res : \@res;
}


1;


__END__
