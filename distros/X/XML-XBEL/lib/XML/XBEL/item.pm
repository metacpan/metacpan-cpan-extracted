use strict;
package XML::XBEL::item;

use base qw (XML::XBEL::base);

=head1 NAME

XML::XBEL::item - private methods for XBEL items.

=head1 SYNOPSIS

 None.

=head1 DESCRIPTION

Private methods for XBEL items.

=cut

# $Id: item.pm,v 1.4 2004/06/23 06:23:57 asc Exp $

use XML::LibXML;

sub title {
    my $self = shift;

    return $self->_element("title",@_);
}

sub desc {
    my $self = shift;

    return $self->_element("desc",$_[0]);
}

sub info {
    my $self = shift;
    my $meta = shift;

    if (! defined($meta)) {

	my @owners = map { 
	    $_->getAttribute("owner");
	} $self->{'__root'}->findnodes("./info/metadata");

	return \@owners;
    }

    #

    my $info = XML::LibXML::Element->new("info");

    foreach my $owner (@{$meta->{owner}}) {

	my $meta = XML::LibXML::Element->new("metadata");
	$meta->setAttribute("owner",$owner);

	$info->appendChild($meta);
    }

    $self->{'__root'}->addChild($info);
    return 1;
}

=head1 VERSION

$Revision: 1.4 $

=head1 DATE

$Date: 2004/06/23 06:23:57 $

=head1 AUTHOR

Aaron Straup Cope E<lt>ascope@cpan.orgE<gt>

=head1 SEE ALSO

<XML::XBEL>

=head1 LICENSE

Copyright (c) 2004 Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the
same terms as Perl itself.

=cut

return 1;
