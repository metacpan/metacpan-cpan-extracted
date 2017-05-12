use strict;
package XML::XBEL::serialize;

=head1 NAME

XML::XBEL::serialize - private methods for serializing XBEL thingies.

=head1 SYNOPSIS

 None.

=head1 DESCRIPTION

Private methods for serializing XBEL thingies.

=cut

# $Id: serialize.pm,v 1.3 2004/06/23 06:30:21 asc Exp $

sub toString {
    my $self = shift;
    $self->{'__root'}->toString(@_);
}

sub toFile {
    my $self = shift;
    $self->{'__root'}->toFile(@_);
}

sub toFH {
    my $self = shift;
    $self->{'__root'}->toFH(@_);
}

=head1 VERSION

$Revision: 1.3 $

=head1 DATE

$Date: 2004/06/23 06:30:21 $

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
