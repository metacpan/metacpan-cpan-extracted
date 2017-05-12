use strict;
package XML::XBEL::thingy;

=head1 NAME

XML::XBEL::thingy - private methods for XBEL thingies.

=head1 SYNOPSIS

 None.

=head1 DESCRIPTION

Private methods for XBEL thingies.

=cut

# $Id: thingy.pm,v 1.2 2004/06/23 06:23:57 asc Exp $

sub delete {
    my $self = shift;

    my $parent = $self->{'__root'}->parentNode();
    $parent->removeChild($self->{'__root'});

    undef $self;
}

sub build_node {
    my $pkg = shift;
    my $node = shift;

    return bless {'__root' => $node}, $pkg;
}

=head1 VERSION

$Revision: 1.2 $

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
