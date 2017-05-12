# -------------------------------------------------------------------------------------
# TripleStore::Query::Variable
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: Variable.pm,v 1.1.1.1 2003/01/13 18:20:40 jhiver Exp $
#
#    Description:
#
#      This object represents a clause variable.
#
# -------------------------------------------------------------------------------------
package TripleStore::Query::Variable;
use strict;
use warnings;
use Carp;


sub new
{
    my $class = shift;
    $class = ref $class || $class;
    return bless {}, $class;
}


1;
