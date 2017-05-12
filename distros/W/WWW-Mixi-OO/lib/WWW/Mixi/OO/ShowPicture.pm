# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: ShowPicture.pm 107 2005-02-05 10:36:02Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/ShowPicture.pm $
package WWW::Mixi::OO::ShowPicture;
use strict;
use warnings;
use base qw(WWW::Mixi::OO::Page);

=head1 NAME

WWW::Mixi::OO::ShowPicture - WWW::Mixi::OO's
L<http://mixi.jp/show_picture.pl> class

=head1 SYNOPSIS

see super class (L<WWW::Mixi::OO::Page>).

=head1 DESCRIPTION

show_picture page handler

=head1 METHODS

=over 4

=cut

=item uri

see super class (L<WWW::Mixi::OO::Page>).

this module handle following params:

=over 4

=item image

image URI.

=back

=cut

sub uri {
    my $this = shift;
    my $options = $this->_init_uri(@_);

    if (exists $options->{image}) {
	$options->{_params}->{img_src} = $options->{image};
    }
    $this->SUPER::uri($options);
}

=item parse_uri

see super class (L<WWW::Mixi::OO::Page>).

this module handle following params:

=over 4

=item image

image URI.

=back

=cut

sub parse_uri {
    my ($this, $data, %options) = @_;

    if (exists $data->{params}->{img_src}) {
	$options{image} = $this->absolute_uri(
	    $data->{params}->{img_src},
	    $this->uri);
    }
    $this->SUPER::parse_uri($data, %options);
}

1;

__END__
=back

=head1 SEE ALSO

L<WWW::Mixi::OO::Page>

=head1 AUTHOR

Topia E<lt>topia@clovery.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Topia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
