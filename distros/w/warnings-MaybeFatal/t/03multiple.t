=pod

=encoding utf-8

=head1 PURPOSE

Test compiling something that produces multiple warnings.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014, 2017 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use lib "t/lib";
use lib "lib";

use Test::More;
use Test::Warnings qw(warnings);
use Test::Fatal qw(exception);

my ($e, @w);

@w = warnings {
	$e = exception { require MultiWarnings };
};

like(
	$w[0],
	qr/^Useless use/,
);

like(
	$w[0],
	qr/^Useless use/,
);

like(
	$e,
	qr{^Compile time warnings at t/lib/MultiWarnings.pm},
);

done_testing;
