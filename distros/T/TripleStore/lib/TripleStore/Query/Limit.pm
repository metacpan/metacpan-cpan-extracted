# -------------------------------------------------------------------------------------
# TripleStore::Query::Limit
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: Limit.pm,v 1.1.1.1 2003/01/13 18:20:40 jhiver Exp $
#
#    Description:
#
#      A criterion is a (operator, value) pair object.
#
# -------------------------------------------------------------------------------------
package TripleStore::Query::Limit;
use strict;
use warnings;
use Carp;


sub new
{
    my $class = shift;
    $class = ref $class || $class;
    return bless [ @_ ], $class;
}


sub offset
{
    my $self = shift;
    if (scalar @{$self} == 1) { return 0          }
    else                      { return $self->[0] }
}


sub rows
{
    my $self = shift;
    if (scalar @{$self} == 1) { return $self->[0] }
    else                      { return $self->[1] }
}


1;


__END__
