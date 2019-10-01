=head1 NAME

XAO::DO::Data::CatalogCategoryMap - category mapping table

=head1 SYNOPSIS

Used internally by the class defined in the import_map property of the
specific catalog.

=head1 DESCRIPTION

Data::CatalogCategoryMap is a Hash that has the following properties:

=over

=item dst_cat

Final category name. Can contain multiple categories levels separated by
double colon (::).

=item src_cat

Catalog's category name. Can contain multiple categories levels
separated by double colon (::).

=back

=cut

###############################################################################
package XAO::DO::Data::CatalogCategoryMap;
use strict;
use XAO::Objects;
use base XAO::Objects->load(objname => 'FS::Hash');
###############################################################################

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: CatalogCategoryMap.pm,v 1.2 2005/01/14 02:08:06 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################
1;
__END__

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/
