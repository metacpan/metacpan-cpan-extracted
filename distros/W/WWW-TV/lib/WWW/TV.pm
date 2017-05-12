=head1 NAME

WWW::TV - Parse TV.com for information about TV shows.

=head1 SYNOPSIS

    use WWW::TV qw();
    my $series = WWW::TV::Series->new(id => 31635);
    my $episode = WWW::TV::Episode->new(id => 475540);

=head1 DESCRIPTION

The L<WWW::TV> modules is a helper package, so you don't need to "use"
the sub modules all the time.

=head1 SEE ALSO

L<WWW::TV::Series>
L<WWW::TV::Episode>

=head1 BUGS

Please report any bugs or feature requests through the web interface
at L<http://rt.cpan.org/Dist/Display.html?Queue=WWW-TV>.

=head1 AUTHOR

Danial Pearce C<cpan@tigris.id.au>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2008 Danial Pearce C<cpan@tigris.id.au>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

package WWW::TV;

use strict;
use warnings;

use WWW::TV::Series;
use WWW::TV::Episode;

our $VERSION = '0.14';

1;

__END__
