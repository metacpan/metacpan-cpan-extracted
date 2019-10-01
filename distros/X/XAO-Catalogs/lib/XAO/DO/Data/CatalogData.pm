=head1 NAME

XAO::DO::Data::CatalogData - untranslated catalog data

=head1 DESCRIPTION

Contains a piece of original catalog that describes one product or one
category or holds extra data that do not belong to any category or
product.

Data::CatalogData is a Hash that has the following properties:

=over

=item type

One of `category', `product' or `extra'.

=item value

Arbitrary content up to 60000 characters long. Depends on the catalog.

=back

=cut

###############################################################################
package XAO::DO::Data::CatalogData;
use strict;
use XAO::Objects;
use base XAO::Objects->load(objname => 'FS::Hash');
###############################################################################

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: CatalogData.pm,v 1.2 2005/01/14 02:08:06 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/
