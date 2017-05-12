use strict;
package XML::XBEL::base;

=head1 NAME

XML::XBEL::base - shared private methods for XBEL thingies

=head1 SYNOPSIS

 None.

=head1 DESCRIPTION

Shared private methods for XBEL thingies.

=cut

# $Id: base.pm,v 1.3 2004/06/23 04:15:12 asc Exp $

use XML::LibXML;
use Date::Format;

sub _now {
    my $pkg = shift;
    return time2str("%Y-%m-%dT%H:%M:%S %z",time);
}

sub _add_node {
    my $self = shift;
    my $node = shift;

    $self->{'__root'}->addChild($node->{'__root'});
}

sub _element {
    my $self    = shift;
    my $element = shift;
    my $value   = shift;

    if (! $value) {
	my $el = ($self->{'__root'}->getChildrenByTagName($element))[0];
	return ($el) ? $el->string_value() : undef;
    }

    #

    if (my $el = ($self->{'__root'}->getChildrenByTagName($element))[0]) {
	$el->removeChild($el->firstChild());
	$el->appendText($value);
    }

    else {
	my $node = XML::LibXML::Element->new($element);
	$node->appendText($value);
	$self->{'__root'}->addChild($node);
    }

    return 1;
}

sub _attribute {
    my $self  = shift;
    my $attr  = shift;
    my $value = shift;

    if (! defined($value)) {
	return $self->{'__root'}->getAttribute($attr);
    }

    $self->{'__root'}->setAttribute($attr,$value);
    return 1;
}

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2004/06/23 04:15:12 $

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
