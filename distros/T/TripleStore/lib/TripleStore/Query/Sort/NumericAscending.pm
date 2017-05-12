# -------------------------------------------------------------------------------------
# TripleStore::Query::Clause::Sort::NumericAscending
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: NumericAscending.pm,v 1.1.1.1 2003/01/13 18:20:40 jhiver Exp $
#
#    Description:
#
#      Sort order for a variable.
#
# -------------------------------------------------------------------------------------
package TripleStore::Query::Sort::NumericAscending;
use strict;
use warnings;
use Carp;
use base qw /TripleStore::Query::Sort/;

sub is_numeric   { 1 }
sub is_ascending { 1 }


1;


__END__
