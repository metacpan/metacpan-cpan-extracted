# -------------------------------------------------------------------------------------
# TripleStore::Mixin::Class
# -------------------------------------------------------------------------------------
#
#       Author : Jean-Michel Hiver (jhiver@mkdoc.com).
#      Version : $Id: Class.pm,v 1.1.1.1 2003/01/13 18:20:40 jhiver Exp $
#
#    Description:
#
#      A simple mixin which provides a class() method which returns the class
#      of an object.
#
# -------------------------------------------------------------------------------------
package TripleStore::Mixin::Class;
use strict;
use warnings;
use Carp;


sub class
{
    my $class = shift;
    $class = ref $class || $class;
    return $class;
}


1;


__END__
