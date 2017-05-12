# -------------------------------------------------------------------------------------
# TripleStore::Mixin::Unimplemented
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: Unimplemented.pm,v 1.1.1.1 2003/01/13 18:20:40 jhiver Exp $
#
#    Description:
#
# -------------------------------------------------------------------------------------
package TripleStore::Mixin::Unimplemented;
use strict;
use warnings;
use Carp;


sub _unimplemented
{
    my $class = shift->class;
    my $method = [ caller (1) ]->[3];
    confess ($class . "::$method is not implemented");
}


1;


__END__
