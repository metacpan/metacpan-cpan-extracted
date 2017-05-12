=pod

=encoding utf8

=head1 PURPOSE

Simple test for L<PerlIO::via::UnicodeDebug>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2012-2013 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use utf8;
use Test::More tests => 1;

use Unicode::Debug;

open my $fh, '>:via(UnicodeDebug)', \(my $file);
print $fh 'Héllò';

is(
	$file,
	'H\\x{00e9}ll\\x{00f2}',
);
