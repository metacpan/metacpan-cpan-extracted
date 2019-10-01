=head1 NAME

XAO::DO::Data::Catalog - object that holds non-translated
vendor catalogs

=head1 SYNOPSIS

 my $catalog=$odb->fetch('/Catalogs/3m');

 $catalog->import_catalog(categories => $odb->fetch('/Categories'),
                          products   => $odb->fetch('/Products'));

=head1 DESCRIPTION

Data::Catalog is a Hash that has the following properties:

=over

=item CategoryMap

Contains a list of Data::CatalogCategoryMap objects describing how to
translate internal categories of the catalog into global categories
table for the site.

See L<XAO::DO::Data::CatalogCategoryMap> for more details.

=item Data

List of Data::CatatalogData objects containing small pieces of original
catalog representing either one product or one category.

See L<XAO::DO::Data::CatalogData> for more details.

=item export_map

Name of export map class that can map from internal products and
categories structure to the specific format of the catalog.

See L<XAO::DO::ExportMap::Base> for more details.

=item import_map

Name of import map class that can map from the specific structure of the
catalog (Data::CatalogData objects) to the site products and categories.

See L<XAO::DO::ImportMap::Base> for more details.

=item source_seq

Each time the catalog is imported into the database this source_seq is
incremented and goes into all the imported products. It is possible to
know then what products were not imported and remove or de-activate
these products in the database.

=back

In addition to being normal Hash data object in OS sense Data::Catalog
provides the following methods:

=over

=cut

###############################################################################

package XAO::DO::Data::Catalog;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'FS::Hash');

use vars qw($VERSION);
$VERSION=(0+sprintf('%u.%03u',(q$Id: Catalog.pm,v 1.3 2005/01/14 02:08:06 am Exp $ =~ /\s(\d+)\.(\d+)\s/))) || die "Bad VERSION";

###############################################################################

=item import_catalog (%)

Takes two arguments -- reference to the categories container and
reference to the products container and translates entire content of the
catalog storing results there.

Example:

 my $catalog=$odb->fetch('/Catalogs/3M');
 my $products=$odb->fetch('/Products');
 my $categories=$odb->fetch('/Categories');

 $catalog->import_catalog(categories => $categories,
                          products => $products);

=cut

sub import_catalog ($%) {
    my $self=shift;
    my $args=get_args(\@_);

    ##
    # Import map object
    #
    my $imap=$self->import_map();

    ##
    # Raw data taken from a catalog
    #
    my $xmlcont=$self->get('Data');

    ##
    # Category map. If it is empty it will be popululated with some
    # initial values.
    #
    my $category_map=$self->get('CategoryMap');
    if($imap->can('check_category_map')) {
        $imap->check_category_map($category_map);
    }

    ##
    # First mapping categories
    #
    my $category_ids;
    if($imap->can('map_xml_categories')) {
        my $catcont=$args->{categories} ||
            throw Error::Simple ref($self)."::import_catalog - no required 'categories' argument found";
        $category_ids=$imap->map_xml_categories($xmlcont,$catcont,$category_map);
    }

    ##
    # And products now.
    #
    my $prodcont=$args->{products} ||
        throw Error::Simple ref($self)."::import_catalog - no required 'products' argument found";
    $imap->map_xml_products($self,
                            $self->container_key(),
                            $xmlcont,
                            $prodcont,
                            $category_ids);

    ##
    # And finally cleaning products that are now out of date.
    #
    my $ref=$self->container_key();
    my $seq=$self->get('source_seq');
    my $ids=$prodcont->search([ 'source_ref', 'eq', $ref ],
                              'and',
                              [ 'source_seq', 'ne', $seq ]);
    foreach my $id (@$ids) {
        dprint "Deleting $id";
        $prodcont->delete($id);
    }
}

###############################################################################

=item import_map ()

Returns ImportMap object for that catalog. Object name is stored in
`import_map' property.

=cut

sub import_map ($) {
    my $self=shift;
    my $imap_objname=$self->get('import_map') ||
        throw Error::Simple "No import map defined for '".$self->container_key."' catalog";
    XAO::Objects->new(objname => $imap_objname);
}

###############################################################################
1;
__END__

=back

=head1 AUTHORS

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/
