use strict;
package XML::XBEL::Bookmark;

use base qw (XML::XBEL::thingy
	     XML::XBEL::item
	     XML::XBEL::url
	     XML::XBEL::node
	     XML::XBEL::serialize);

# $Id: Bookmark.pm,v 1.4 2004/06/23 06:23:57 asc Exp $

=head1 NAME

XML::XBEL::Bookmark - OOP for reading and writing XBEL bookmarks.

=head1 SYNOPSIS

 use XML::XBEL::Bookmark;

=head1 DESCRIPTION

OOP for reading and writing XBEL bookmarks.

=cut

use XML::LibXML;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Valid args are:

=over 4

=item * B<title>

String.

=item * B<href>

String.

=item * B<id>

String.

=item * B<desc>

String.

=item * B<added>

String.

=item * B<modified>

String.

=item * B<visited>

String.

=item * B<info>

Hash ref, with the following key/value pairs :

=over 6

=item * I<owner>

Array ref.

=back

=back

Returns a I<XML::XBEL::Bookmark> object.

=cut

sub new {
    my $pkg  = shift;
    my $args = shift;

    my $root = XML::LibXML::Element->new("bookmark");
    my $self = bless {'__root' => $root }, $pkg;

    foreach my $el ("title","href","id","desc","added","info","modified","visited") {

	if (! exists($args->{$el})) {
	    next;
	}

	$self->$el($args->{$el});
    }

    if (! $self->added()) {
	$self->added($self->_now());
    }

    return $self;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->href(href)

Get/set the href attribute for an XBEL bookmark.

If modified, the object's I<modified> method is
automatically called with the current datetime.

=cut

sub href {
    my $self = shift;
    my $href = shift;

    if (defined($href)) {
	$self->modified($self->_now());
    }

    return $self->SUPER::href($href);
}

=head2 $obj->title($title)

Get/set the title for an XBEL bookmark.

If modified, the object's I<modified> method is
automatically called with the current datetime.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

sub title {
    my $self = shift;
    my $title = shift;

    if (defined($title)) {
	$self->modified($self->_now());
    }

    return $self->SUPER::title($title);
}

=head2 $obj->desc($description)

Get/set the description for an XBEL bookmark.

If modified, the object's I<modified> method is
automatically called with the current datetime.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

# Defined in XML::XBEL::item

=head2 $obj->info(\%args)

Get/set the metadata for an XBEL document.

Valid args are :

=over 4

=item * B<owner>

Array reference

=back

Returns an array reference when called with no arguments;
otherwise returns true or false.

=cut

=head2 $obj->id($id)

Get/set the id attribute for an XBEL bookmark.

If modified, the object's I<modified> method is
automatically called with the current datetime.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

sub id {
    my $self = shift;
    my $id   = shift;

    if (defined($id)) {
	$self->modified($self->_now());
    }

    return $self->SUPER::id($id);
}

=head2 $obj->added($datetime)

Get/set the creation datetime for an XBEL bookmark.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

# Defined in XML::XBEL::node

=head2 $obj->modified($datetime)

Get/set the last modified datetime for an XBEL bookmark.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

# Defined in XML::XBEL::url

=head2 $obj->visited($datetime)

Get/set the last visited datetime for an XBEL bookmark.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

# Defined in XML::XBEL::url

=head2 $obj->toString($format)

=cut

# Defined in XML::XBEL::serialize

=head2 $obj->toFile($filename,$format)

=cut

# Defined in XML::XBEL::serialize

=head2 $obj->toFH(\*$fh,$format)

=cut

# Defined in XML::XBEL::serialize

=head1 VERSION

$Revision: 1.4 $

=head1 DATE

$Date: 2004/06/23 06:23:57 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<XML::XBEL>

L<XML::XBEL::Folder>

L<XML::XBEL::Alias>

L<XML::XBEL::Separator>

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
