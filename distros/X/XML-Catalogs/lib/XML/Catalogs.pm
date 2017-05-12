use 5;

package XML::Catalogs;

use strict;
use warnings;

use version; our $VERSION = qv('v1.0.3');


use File::ShareDir qw( );


sub import {
    my $class = shift;
    for (@_) {
        if ($_ eq -libxml) {
            $class->notify_libxml()
        } else {
            require Carp;
            Carp::croak("Unrecognized import $_");
        }
    }
}


sub get_catalog_path {
    my $class = shift;
    my $path;
    return $path if eval {
        $path = File::ShareDir::module_file($class, 'catalog.xml'); 1 };
    require Carp;
    Carp::croak("Can't locate ${class}'s catalog");
}


sub get_catalog_url {
    my $class = shift;
    require URI::file;
    return URI::file->new($class->get_catalog_path());
}


sub notify_libxml {
    my $class = shift;
    require XML::LibXML;
    XML::LibXML->VERSION(1.53);
    XML::LibXML->load_catalog(
        $class->get_catalog_path()
    );
}


1;

__END__

=head1 NAME

XML::Catalogs - Basic framework to provide DTD catalogs


=head1 VERSION

Version 1.0.3


=head1 SYNOPSIS

    To make a catalog:

        Use XML::Catalogs::HTML as an example

    To use a catalog:

        use XML::Catalogs::FOO -libxml;

            ---

        use XML::Catalogs::FOO;

        XML::Catalogs->notify_libxml();

            ---

        use XML::Catalogs::FOO;

        my $url  = XML::Catalogs::FOO->get_catalog_url();
        my $path = XML::Catalogs::FOO->get_catalog_path();


=head1 DESCRIPTION

To properly parse named entities in an XML document,
the parser must have access to the XML subformat's DTDs.

L<XML::LibXML>, for one, does not cache DTDs it downloads.
Instead, it relies on them being in the system's XML catalog.
This is not always configured properly for a number of
reasons.

An XML catalog is simply a set of DTDs and a table of contents
that associates DTD identifiers with the DTDs.

This module provides a simple framework to package XML catalogs.
It also provides a simple method to notify XML::LibXML of DTDs
that may not be present in the system's catalog.

It works on all platforms, it works without requiring root
priviledges, and it works with CPAN's dependency system.


=head1 CLASS METHODS

=over

=item C<< use XML::Catalogs::FOO -libxml >>

This loads XML::Catalogs::FOO and calls
C<< XML::Catalogs::FOO->notify_libxml() >>


=item C<< $subclass->notify_libxml() >>

This method informs L<XML::LibXML> of the subclass's
catalog. XML::LibXML will use the local DTDs
referenced by the catalog instead of downloading
them. This only affects the current process.

This mechanism does not stop working when XML::LibXML's
C<< no_network => 1 >> option is used.

Note that XML::LibXML version 1.53 is required for
this features.


=item C<< $subclass->get_catalog_url() >>

Returns a file:// URL to the subclass's catalog.


=item C<< $subclass->get_catalog_path() >>

Returns the file path of the subclass's catalog.


=back

=head1 SEE ALSO

=over 4

=item * L<http://en.wikipedia.org/wiki/XML_Catalog>, Wikipedia's entry on XML Catalogs.

=item * L<XML::LibXML>, an excellent XML parser that supports catalogs.

=item * L<XML::Catalogs::HTML>, a module using this framework.

=item * L<http://www.w3.org/blog/systeam/2008/02/08/w3c_s_excessive_dtd_traffic>, An example of the real world effects of not having local DTDs.

=back


=head1 BUGS

Please report any bugs or feature requests to C<bug-XML-Catalogs at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XML-Catalogs>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XML::Catalogs

You can also look for information at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/XML-Catalogs>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XML-Catalogs>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XML-Catalogs>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XML-Catalogs>

=back


=head1 AUTHOR

Eric Brine, C<< <ikegami@adaelis.com> >>


=head1 COPYRIGHT & LICENSE

No rights reserved.

The author has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.


=cut
