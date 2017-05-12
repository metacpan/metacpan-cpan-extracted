# -------------------------------------------------------------------------------------
# TripleStore::Query::Clause::Sort::StringDescending
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: StringDescending.pm,v 1.1.1.1 2003/01/13 18:20:40 jhiver Exp $
#
#    Description:
#
#      Sort order for a variable.
#
# -------------------------------------------------------------------------------------
package TripleStore::Query::Sort::StringDescending;
use strict;
use warnings;
use Carp;
use base qw /TripleStore::Query::Sort/;

sub is_numeric   { 0 }
sub is_ascending { 0 }


1;


__END__
