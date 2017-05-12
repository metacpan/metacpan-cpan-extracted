package MGX;

use 5.005_03;
$VERSION = '1.23';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use XS::MagicExt;

1;

__END__

=head1 NAME

MGX - A testing module for XS::MagicExt

=head1 AUTHOR

Goro Fuji (gfx) E<lt>gfuji(at)cpan.orgE<gt>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009, Goro Fuji (gfx). Some rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
