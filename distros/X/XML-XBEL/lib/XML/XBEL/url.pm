use strict;
package XML::XBEL::url;

use base qw (XML::XBEL::base);

=head1 NAME

XML::XBEL::url - private methods for XBEL URLs.

=head1 SYNOPSIS

 None.

=head1 DESCRIPTION

Private methods for XBEL URLs.

=cut

# $Id: url.pm,v 1.2 2004/06/23 04:15:13 asc Exp $

sub href {
    my $self = shift;
    return $self->_attribute("href",$_[0]);
}

sub visited {
    my $self = shift;
    return $self->_attribute("visited",@_);
}

sub modified {
    my $self = shift;

    return $self->_attribute("modified",@_);
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
