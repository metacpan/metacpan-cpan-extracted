use strict;
package XML::XBEL::Alias;

use base qw (XML::XBEL::base
	     XML::XBEL::thingy
	     XML::XBEL::serialize);

# $Id: Alias.pm,v 1.4 2004/06/23 06:23:57 asc Exp $

=head1 NAME

XML::XBEL::Alias - OOP for reading and writing XBEL aliases.

=head1 SYNOPSIS

 use XML::XBEL::Alias;

=head1 DESCRIPTION

OOP for reading and writing XBEL aliases.

=cut

use XML::LibXML;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new(\%args)

Valid args are :

=over 4

=item * B<ref>

String.

=back

Returns an I<XML::XBEL::Alias> object.

=cut

sub new {
    my $pkg  = shift;
    my $args = shift;

    my $root = XML::LibXML::Element->new("alias");
    my $self = bless {'__root' => $root }, $pkg;

    foreach my $el ("ref") {

	if (! exists($args->{$el})) {
	    next;
	}

	$self->$el($args->{$el});
    }

    return $self;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->ref((XML::XBEL::Bookmark || $pointer_)

Get/set the reference for an alias.

Returns a string when called with no arguments;
otherwise returns true or false.

=cut

sub ref {
    my $self    = shift;
    my $pointer = shift;

    if (ref($pointer) eq "XML::XBEL::Bookmark") {
	return $self->_attribute("ref",$pointer->id());
    }

    # It would be nice to return the actual
    # XML::XBEL::Bookmark object instead of
    # just a string...

    return $self->_attribute("ref",$pointer);
}

=head2 $obj->delete()

Delete an XBEL alias.

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

$Revision: 1.4 $

=head1 DATE

$Date: 2004/06/23 06:23:57 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<XML::XBEL>

L<XML::XBEL::Folder>

L<XML::XBEL::Bookmark>

L<XML::XBEL::Separator>

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
