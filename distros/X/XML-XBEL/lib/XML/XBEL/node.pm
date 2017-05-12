use strict;
package XML::XBEL::node;

use base qw (XML::XBEL::base);

=head1 NAME

XML::XBEL::node - private methods for XBEL nodes.

=head1 SYNOPSIS

 None.

=head1 DESCRIPTION

Private methods for XBEL nodes.

=cut

# $Id: node.pm,v 1.2 2004/06/23 04:15:13 asc Exp $

sub id {
    my $self = shift;

    return $self->_attribute("id",$_[0]);
}

sub added {
    my $self = shift;

    return $self->_attribute("added",@_);
}

=head1 VERSION

$Revision: 1.2 $

=head1 DATE

$Date: 2004/06/23 04:15:13 $

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
