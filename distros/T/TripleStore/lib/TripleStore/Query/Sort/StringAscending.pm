# -------------------------------------------------------------------------------------
# TripleStore::Query::Clause::Sort::StringAscending
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: StringAscending.pm,v 1.1.1.1 2003/01/13 18:20:40 jhiver Exp $
#
#    Description:
#
#      Sort order for a variable.
#
# -------------------------------------------------------------------------------------
package TripleStore::Query::Sort::StringAscending;
use strict;
use warnings;
use Carp;
use base qw /TripleStore::Query::Sort/;

sub is_numeric   { 0 }
sub is_ascending { 1 }


1;


__END__
