use strict;
package XML::XBEL::container;

use base qw (XML::XBEL::base);

=head1 NAME

XML::XBEL::container - private methods for XBEL containers.

=head1 SYNOPSIS

 None.

=head1 DESCRIPTION

Private methods for XBEL containers.

=cut

# $Id: container.pm,v 1.5 2004/06/24 02:15:15 asc Exp $

sub bookmarks {
    my $self = shift;

    return $self->_find_children("bookmark","XML::XBEL::Bookmark",@_);
}

sub add_bookmark {
    my $self = shift;

    require XML::XBEL::Bookmark;
    $self->_add_item("XML::XBEL::Bookmark",@_);
}

sub folders {
    my $self      = shift;

    return $self->_find_children("folder","XML::XBEL::Folder",@_);
}

sub add_folder {
    my $self   = shift;

    require XML::XBEL::Folder;
    $self->_add_item("XML::XBEL::Folder",@_);
}

sub aliases {
    my $self      = shift;

    return $self->_find_children("alias","XML::XBEL::Alias",@_);
}

sub add_alias {
    my $self = shift;

    require XML::XBEL::Alias;
    $self->_add_item("XML::XBEL::Alias",@_);
}

sub add_separator {
    my $self = shift;
    my $obj  = shift;

    if (ref($obj) ne "XML::XBEL::Separator") {

	require XML::XBEL::Separator;
	$obj = XML::XBEL::Separator->new();
    }

    $self->_add_item("XML::XBEL::Separator",$obj);
}

sub _add_item {
    my $self  = shift;
    my $class = shift;
    my $what  = shift;

    if (ref($what) eq $class) {
	$self->_add_node($what);
    }

    elsif (ref($what) eq "HASH") {
	my $obj = $class->new($what);
	$self->_add_node($obj);
    }

    else {
	return undef;
    }

    return 1;
}

sub _find_children {
    my $self      = shift;
    my $child     = shift;
    my $class     = shift;
    my $recursive = shift;

    eval "require $class";

    my $xpath = ($recursive) ? "./descendant::*[name()='$child']" :
	"./child::*[name()='$child']";

    return map {
	$class->build_node($_);
    } $self->{'__root'}->findnodes($xpath);
}

=head1 VERSION

$Revision: 1.5 $

=head1 DATE

$Date: 2004/06/24 02:15:15 $

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
