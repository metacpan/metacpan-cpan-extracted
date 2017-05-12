package XML::Atom::Service;

use warnings;
use strict;
use Carp;

use XML::Atom 0.27;
use XML::Atom::Workspace;
use XML::Atom::Collection;
use XML::Atom::Categories;
use XML::Atom::Atompub;
use base qw(XML::Atom::Thing);

use version; our $VERSION = qv('0.16.2');

#our $DefaultNamespace = 'http://purl.org/atom/app#';
our $DefaultNamespace = 'http://www.w3.org/2007/app';

$XML::Atom::DefaultVersion = '1.0';

sub element_name { 'service' }

sub element_ns { $DefaultNamespace }

__PACKAGE__->mk_object_list_accessor('workspace' => 'XML::Atom::Workspace', 'workspaces');

1;
__END__

=head1 NAME

XML::Atom::Service - Atom Service Document object


=head1 COMPATIBILITY ISSUES

L<XML::Atom::Service> has B<changed the default namespace> since v0.15.0.
The new namespaces are 'http://www.w3.org/2005/Atom' and 'http://www.w3.org/2007/app'.

See L<NAMESPACES> in details.


=head1 SYNOPSIS

  use XML::Atom::Service;

  my $category = XML::Atom::Category->new;
  $category->term('joke');
  $category->scheme('http://example.org/extra-cats/');

  my $categories = XML::Atom::Categories->new;
  $categories->add_category($category);

  my $collection = XML::Atom::Collection->new;
  $collection->href('http://example.org/reilly/main');
  $collection->title('My Blog Entries');
  $collection->add_accept('application/atom+xml;type=entry');
  $collection->add_categories($categories);

  my $workspace = XML::Atom::Workspace->new;
  $workspace->title('Main Site');
  $workspace->add_collection($collection);

  my $service = XML::Atom::Service->new;
  $service->add_workspace($workspace);

  my $xml = $service->as_xml;

  # Get lists of the workspace, collection, and categories elements
  my @workspace = $service->workspaces;
  my @collection = $workspace[0]->collections;
  my @categories = $collection[0]->categories;


=head1 DESCRIPTION

The Atom Publishing Protocol (Atompub) is a protocol for publishing and 
editing Web resources described at
L<http://www.ietf.org/internet-drafts/draft-ietf-atompub-protocol-17.txt>.

L<XML::Atom::Service> is an Service Document implementation.
In the Atom Publishing Protocol, a client needs to first discover the 
capabilities and locations of Collections.
The Service Document is designed to support this discovery process.
The document describes the location and capabilities of Collections.

The Atom Publishing Protocol introduces some new XML elements, such as
I<app:edited> and I<app:draft>, which are imported into L<XML::Atom>.
See L<XML::Atom::Atompub> in detail.

This module was tested in InteropTokyo2007
L<http://intertwingly.net/wiki/pie/July2007InteropTokyo>, 
and interoperated with other implementations.


=head1 METHODS

=head2 XML::Atom::Service->new([ $stream ])

Creates a new Service Document object, and if $stream is supplied, fills 
it with the data specified by $stream.

Automatically handles autodiscovery if $stream is a URI (see below).

Returns the new L<XML::Atom::Service> object. On failure, returns C<undef>.

$stream can be any one of the following:

=over 4

=item * Reference to a scalar

This is treated as the XML body of the Service Document.

=item * Scalar

This is treated as the name of a file containing the Service Document XML.

=item * Filehandle

This is treated as an open filehandle from which the Service Document XML can be read.

=item * URI object

This is treated as a URI, and the Service Document XML will be retrieved from the URI.

=back

=head2 $service->workspace

If called in scalar context, returns an L<XML::Atom::Workspace> object
corresponding to the first "app:workspace" element found in the Service 
Document.

If called in list context, returns a list of L<XML::Atom::Workspace> objects
corresponding to all of the app:workspace elements found in the Service Document.

=head2 $service->add_workspace($workspace)

Adds the workspace $workspace, which must be an L<XML::Atom::Workspace> object, to
the Service Document as a new app:workspace element. For example:

    my $workspace = XML::Atom::Workspace->new;
    $workspace->title('Foo Bar');
    $service->add_workspace($workspace);

=head2 $service->element_name

=head2 $service->element_ns


=head1 NAMESPACES

By default, L<XML::Atom::Service> will create entities using the new
Atom namespaces, 'http://www.w3.org/2005/Atom' and 'http://www.w3.org/2007/app'.
In order to use old ones, you can set them by setting global variables like:

  use XML::Atom;
  use XML::Atom::Service;
  $XML::Atom::DefaultVersion = '0.3';   # 'http://purl.org/atom/ns#'
  $XML::Atom::Service::DefaultNamespace = 'http://purl.org/atom/app#';


=head1 SEE ALSO

L<XML::Atom>
L<Atompub>
L<Catalyst::Controller::Atompub>


=head1 AUTHOR

Takeru INOUE, E<lt>takeru.inoue _ gmail.comE<gt>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Takeru INOUE C<< <takeru.inoue _ gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
