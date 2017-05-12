=head1 NAME

XAO::DO::Data::Product - default dynamic data object for Data::Product

=head1 SYNOPSIS

None

=head1 DESCRIPTION

The Data::Product object is derived from XAO::FS::Hash and does not add
any new methods.

=cut

###############################################################################
package XAO::DO::Data::Product;
use strict;
use XAO::Objects;

use vars qw(@ISA);
@ISA=XAO::Objects->load(objname => 'FS::Hash');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Product.pm,v 2.1 2005/01/14 00:23:54 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################
1;
__END__

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/
