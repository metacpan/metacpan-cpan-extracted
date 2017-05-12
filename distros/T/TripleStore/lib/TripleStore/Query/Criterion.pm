# -------------------------------------------------------------------------------------
# TripleStore::Query::Criterion
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: Criterion.pm,v 1.1.1.1 2003/01/13 18:20:40 jhiver Exp $
#
#    Description:
#
#      A criterion is a (operator, value) pair object.
#
# -------------------------------------------------------------------------------------
package TripleStore::Query::Criterion;
use strict;
use warnings;
use Carp;


sub new
{
    my $class = shift;
    $class = ref $class || $class;
    unshift @_, 'eq' if (@_ < 2);
    push @_, undef   if (@_ < 2);
    return bless [ @_ ], $class;
}


sub is_numeric_operator
{
    my $self = shift;
    $self->[0] eq '==' and return 1;
    $self->[0] eq '!=' and return 1;
    $self->[0] eq '<=' and return 1;
    $self->[0] eq '>=' and return 1;
    $self->[0] eq '<'  and return 1;
    $self->[0] eq '>'  and return 1;
    return 0;
}


sub operator
{
    my $self = shift;
    return $self->[0];
}


sub value
{
    my $self = shift;
    return $self->[1];
}


1;


__END__
