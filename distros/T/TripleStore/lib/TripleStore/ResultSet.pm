# -------------------------------------------------------------------------------------
# TripleStore::ResultSet
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: ResultSet.pm,v 1.1.1.1 2003/01/13 18:20:39 jhiver Exp $
#
#    Description:
#
#      This object represents the set of results that a given query
#      has performed.
#
# -------------------------------------------------------------------------------------
package TripleStore::ResultSet;
use strict;
use warnings;
use Carp;
use base qw /TripleStore::Mixin::Class
	     TripleStore::Mixin::Unimplemented/;


##
# $class->next();
# ---------------
# Returns the next record as an array reference.
# Returns nothing where there's nothing to return.
# Returns - An array reference.
##
sub next
{
    my $class = shift->class;
    return $class->_unimplemented();
}


##
# $class->fetch_all();
# --------------------
# Returns - An arrayref in scalar context or an array in list context.
##
sub fetch_all
{
    my $self = shift;
    my @res  = ();
    while (my $arrayref = $self->next()) { push @res, $arrayref };
    return wantarray ? @res : \@res;
}


1;
