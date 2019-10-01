=head1 NAME

XAO::DO::Catalogs - XAO catalog exchange module

=head1 SYNOPSIS

 xao-ifilter-sample --debug sample_site sample.xml
 xao-import-map --debug sample_site sample

=head1 DESCRIPTION

XAO Catalogs is a Perl module that supports integrating multiple
manufacturers' catalogs into a single products database. This can be
used for eCommerce sites, data integration projects, and search and
comparison engines.

=head1 METHODS

XAO::DO::Catalogs contains only minor utility methods, all real
functionality is in ImportMap::Base and specific import maps based on
it.

=over

=cut

###############################################################################
package XAO::DO::Catalogs;
use strict;
use XAO::Objects;
use XAO::Projects;
use base XAO::Objects->load(objname => 'Atom');

use vars qw($VERSION);
$VERSION='1.04';

###############################################################################

=item build_structure ()

Builds supporting structure in the database. Does not destroy existing
data -- safe to call on already populated database.

Usually should be called in Config.pm's build_structure() method.

=cut

sub build_structure ($) {
    my $self=shift;
    my $siteconfig=XAO::Projects::get_current_project();
    my $odb=$siteconfig->odb;

    $odb->fetch('/')->build_structure($self->data_structure);
}

###############################################################################

=item data_structure ()

Returns a reference to a hash that describes database structure. Usually
you would add it to your database description in Config.pm:

 my $cobj=XAO::Objects->new(objname => 'Catalogs');

 my %structure=(
     MyData => {
         ...
     },

     %{$cobj->data_structure},

     MyOtherData => {
         ...
     }
 );

If that looks ugly (it is ugly) then look at the build_structure()
method description instead.

=cut

sub data_structure ($) {
    my $self=shift;

    my %structure=(
        Catalogs => {
            type        => 'list',
            class       => 'Data::Catalog',
            key         => 'catalog_id',
            structure   => {
                CategoryMap => {
                    type        => 'list',
                    class       => 'Data::CatalogCategoryMap',
                    key         => 'id',
                    structure   => {
                        src_cat => {
                            type        => 'text',
                            maxlength   => 200,
                        },
                        dst_cat => {
                            type        => 'text',
                            maxlength   => 200,
                        },
                    },
                },
                Data => {
                    type        => 'list',
                    class       => 'Data::CatalogData',
                    key         => 'id',
                    structure   => {
                        type => {
                            type        => 'text',
                            maxlength   => 10,
                            index       => 1,
                        },
                        value => {
                            type        => 'text',
                            maxlength   => 60000,
                        },
                    },
                },
                export_map => {
                    type        => 'text',
                    maxlength   => 100,
                },
                import_map => {
                    type        => 'text',
                    maxlength   => 100,
                },
                manufacturer => {
                    type        => 'text',
                    maxlength   => 100,
                },
                source_seq => {
                    type        => 'integer',
                    minvalue    => 0,
                },
            },
        },
    );

    return \%structure;
}

1;
###############################################################################
__END__

=back

=head1 AUTHOR

Copyright (c) 2005 Andrew Maltsev

Copyright (c) 2001-2004 Andrew Maltsev, XAO Inc.

<am@ejelta.com> -- http://ejelta.com/xao/

=head1 SEE ALSO

Recommended reading:
L<XAO::DO::ImportMap::Base>,
L<XAO::Objects>,
L<XAO::Web>,
L<XAO::Commerce>.
