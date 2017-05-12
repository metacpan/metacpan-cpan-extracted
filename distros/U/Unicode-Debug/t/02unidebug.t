=pod

=encoding utf8

=head1 PURPOSE

Simple tests for L<Unicode::Debug>.

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
use Test::More tests => 3;

use Unicode::Debug;

is(
	unidebug('Héllò'),
	'H\\x{00e9}ll\\x{00f2}',
	'normal behaviour',
);

$Unicode::Debug::Names = 1;
is(
	unidebug('Héllò'),
	'H\N{LATIN SMALL LETTER E WITH ACUTE}ll\N{LATIN SMALL LETTER O WITH GRAVE}',
	'with names',
);

$Unicode::Debug::Whitespace = 1;
is(
	unidebug("\tHello\r\n"),
	"\\tHello\\r\\n\n",
	'with whitespace',
);
