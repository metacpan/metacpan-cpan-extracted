# -*- cperl -*-
# copyright (C) 2005 Topia <topia@clovery.jp>. all rights reserved.
# This is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
# $Id: Home.pm 96 2005-02-04 16:55:48Z topia $
# $URL: file:///usr/minetools/svnroot/mixi/trunk/WWW-Mixi-OO/lib/WWW/Mixi/OO/Home.pm $
package WWW::Mixi::OO::Home;
use strict;
use warnings;
use base qw(WWW::Mixi::OO::Page);

=head1 NAME

WWW::Mixi::OO::Home - WWW::Mixi::OO's L<http://mixi.jp/home.pl> class

=head1 SYNOPSIS

  my $page = $mixi->page('home');
  $page->uri;
  # some implementations...

=head1 DESCRIPTION

home page handler

=head1 METHODS

=over 4

=cut

=item uri

see parent class (L<WWW::Mixi::OO::Page>).

=cut

sub uri { shift->absolute_uri('home') }

=back

=head1 MISSING FEATURE

=over 4

=item information handler

=back

=cut

# some implementations need

1;

__END__
=back

=head1 SEE ALSO

L<WWW::Mixi::OO::Page>,
L<WWW::Mixi::OO::Session>

=head1 AUTHOR

Topia E<lt>topia@clovery.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Topia.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

