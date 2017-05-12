package dtRdr::Metadata::Book;
$VERSION = eval{require version}?version::qv($_):$_ for(0.0.1);

use warnings;
use strict;
use Carp;

=head1 NAME

dtRdr::Metadata::Book - metadata for books

=head1 SYNOPSIS

This package provides the base API for book metadata.  Plugins may
define the METADATA_CLASS constant to override this.

=cut

# TODO use base 'dtRdr::Metadata';

use Class::Accessor::Classy;
with 'new';
rw this->PROPS;
no  Class::Accessor::Classy;

=head1 Constructor

=head2 new

We provide the standard Class::Accessor::Classy constructor.

=head1 Class Methods

=head2 PROPS

A list of properties for this metadata class.

  my @proplist = dtRdr::Metadata::Book->PROPS;

=cut

use constant PROPS => qw(
  annotation_server
);

=head1 Inner Data Objects

=head2 dtRdr::Metadata::Book::annotation_server

  $meta->set_annotation_server(
    dtRdr::Metadata::Book::annotation_server->new(
      id   => $something_unique,
      uri  => 'http://example.com/anno_server/',
    )
  );

=cut

{
  package dtRdr::Metadata::Book::annotation_server;
  use Class::Accessor::Classy;
  with 'new';
  rw qw(id uri);
  no  Class::Accessor::Classy;
}

=head1 TODO: hashref culling object

The book plugins are probably going to end up repeating each other if we
don't do something like:

  my $props = dtRdr::MetaProps->new(%big_list_of_junk);
  $props->cull_to($book, %book_name_remap);
  $props->cull_to($meta, %meta_name_remap);
  warn 'ack! ', %$props if $props->leftovers;

=head1 AUTHOR

Eric Wilhelm <ewilhelm at cpan dot org>

http://scratchcomputing.com/

=head1 COPYRIGHT

Copyright (C) 2007 Eric L. Wilhelm and OSoft, All Rights Reserved.

=head1 NO WARRANTY

Absolutely, positively NO WARRANTY, neither express or implied, is
offered with this software.  You use this software at your own risk.  In
case of loss, no person or entity owes you anything whatsoever.  You
have been warned.

=head1 LICENSE

The dotReader(TM) is OSI Certified Open Source Software licensed under
the GNU General Public License (GPL) Version 2, June 1991. Non-encrypted
and encrypted packages are usable in connection with the dotReader(TM).
The ability to create, edit, or otherwise modify content of such
encrypted packages is self-contained within the packages, and NOT
provided by the dotReader(TM), and is addressed in a separate commercial
license.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

# vi:ts=2:sw=2:et:sta
1;
