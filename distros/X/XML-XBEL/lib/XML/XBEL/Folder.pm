use strict;
package XML::XBEL::Folder;

use base qw (XML::XBEL::thingy
	     XML::XBEL::item
	     XML::XBEL::node
	     XML::XBEL::container
	     XML::XBEL::serialize);

=head1 NAME

XML::XBEL::Folder - OOP for reading/writing XBEL folders.

=head1 SYNOPSIS

 use XML::XBEL::Folder;

=head1 DESCRIPTION

OOP for reading/writing XBEL folders.

=cut

# $Id: Folder.pm,v 1.5 2004/06/24 02:15:15 asc Exp $

use XML::LibXML;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Valid arguments are :

=over 4

=item * B<title>

String.

=item * B<desc>

String.

=item * B<id>

String.

=item * B<added>

String.

=item * B<folded>

I<yes> (default) or I<no>.

=item * B<info>

Hash ref, with the following key/value pairs :

=over 6

=item * I<owner>

Array ref.

=back

=back

Returns a I<XML::XBEL::Folder> object.

=cut

sub new {
    my $pkg  = shift;
    my $args = shift;
    
    my $root = XML::LibXML::Element->new("folder");
    my $self = bless {'__root' => $root }, $pkg;

    foreach my $el ("title","desc","info","id","added","folded") {

	if (! exists($args->{$el})) {
	    next;
	}

	$self->$el($args->{$el});
    }

    if (! $self->added()) {
	$self->added($self->_now());
    }

    if (! $self->folded()) {
	$self->folded(1);
    }

    return $self;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->title($title)

Get/set the title for an XBEL folder.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

# Defined in XML::XBEL::item

=head2 $obj->desc($description)

Get/set the description for an XBEL folder.

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

Get/set the id attribute for an XBEL folder.

=cut

# Defined in XML::XBEL::node

=head2 $obj->added($datetime)

Get/set the creation datetime for an XBEL folder.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

# Defined in XML::XBEL::node

=head2 $obj->folded($bool)

Get/set the I<folded> state for an XBEL folder.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

sub folded {
    my $self = shift;
    my $bool = shift;

    if ((defined($bool)) && ($bool ne "no")) {

	$bool = ($bool) ? "yes" : "no";
    }

    $self->_attribute("folded",$bool);
}

=head2 $obj->bookmarks($recursive)

Returns a list of child I<XML::XBEL::Bookmark> objects.

Where I<$recursive> is a boolean indicating whether to
return all the bookmarks in an XBEL folder or only its
immediate children.

=cut

# Defined in XML::XBEL::container

=head2 $obj->folders($recursive)

Returns a list of child I<XML::XBEL::Folder> objects.

Where I<$recursive> is a boolean indicating whether to
return all the folders in an XBEL folder or only its
immediate children.

=cut

# Defined in XML::XBEL::container

=head2 $obj->aliases($recursive)

Returns a list of child I<XML::XBEL::Alias> objects.

Where I<$recursive> is a boolean indicating whether to
return all the aliases in an XBEL folder or only its
immediate children.

=cut

# Defined in XML::XBEL::container

=head2 $obj->add_bookmark(XML::XBEL::Bookmark)

Add a new bookmark to an XBEL folder.

If passed a hash ref, valid arguments are the same as those
defined for the I<XML::XBEL::Bookmark> object constructor.

=cut

# Defined in XML::XBEL::container

=head2 $obj->add_folder(XML::XBEL::Folder)

Add a new folder to an XBEL folder.

If passed a hash ref, valid arguments are the same as those
defined for the I<XML::XBEL::Folder> object constructor.

=cut

# Defined in XML::XBEL::container

=head2 $obj->add_alias(XML::XBEL::Alias)

Add a new alias to an XBEL folder.

If passed a hash ref, valid arguments are the same as those
defined for the I<XML::XBEL::Alias> object constructor.

=cut

# Defined in XML::XBEL::container

=head2 $obj->delete()

Delete an XBEL folder.

=cut

# Defined in XML::XBEL::thingy

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

$Revision: 1.5 $

=head1 DATE

$Date: 2004/06/24 02:15:15 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<XML::XBEL>

L<XML::XBEL::Bookmark>

L<XML::XBEL::Alias>

L<XML::XBEL::Separator>

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
