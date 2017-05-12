use strict;
package XML::XBEL::Separator;

use base qw (XML::XBEL::base
	     XML::XBEL::thingy
	     XML::XBEL::serialize);

# $Id: Separator.pm,v 1.2 2004/06/23 04:15:12 asc Exp $

=head1 NAME

XML::XBEL::Separator - OOP for reading and writing XBEL separators

=head1 SYNOPSIS

 use XML::XBEL::Separator;

=head1 DESCRIPTION

OOP for reading and writing XBEL separators

=cut

use XML::LibXML;

=head1 PACKAGE METHODS

=cut

=head2 __PACKAGE__->new()

Returns an I<XML::XBEL::Separator> object.

=cut

sub new {
    my $pkg = shift;

    my $root = XML::LibXML::Element->new("separator");
    my $self = bless {'__root' => $root }, $pkg;

    return $self;
}

=head1 OBJECT METHODS

=cut

=head2 $obj->delete()

Delete an XBEL separator.

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

$Revision: 1.2 $

=head1 DATE

$Date: 2004/06/23 04:15:12 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

L<XML::XBEL>

L<XML::XBEL::Folder>

L<XML::XBEL::Bookmark>

L<XML::XBEL::Alias>

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All rights reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
