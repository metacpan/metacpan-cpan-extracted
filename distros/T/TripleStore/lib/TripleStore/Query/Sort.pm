# -------------------------------------------------------------------------------------
# TripleStore::Query::Clause::Sort
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: Sort.pm,v 1.1.1.1 2003/01/13 18:20:40 jhiver Exp $
#
#    Description:
#
#      Sort order for a variable.
#
# -------------------------------------------------------------------------------------
package TripleStore::Query::Sort;
use strict;
use warnings;
use Carp;
use base qw /TripleStore::Mixin::Class
	     TripleStore::Mixin::Unimplemented/;

sub new { return bless \$_[1], $_[0]->class }
sub is_numeric   { shift->_unimplemented (@_) }
sub is_ascending { shift->_unimplemented (@_) }


1;


__END__
