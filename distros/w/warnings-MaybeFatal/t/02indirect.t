=pod

=encoding utf-8

=head1 PURPOSE

Test that one module using warnings::MaybeFatal is able to load another
module using warnings::MaybeFatal.

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
use Test::Warnings qw(warning);
use Test::Fatal qw(exception);

like(
	exception { require LoadsThisShouldDie },
	qr/^Useless use/,
);

like(
	warning { require LoadsThisShouldWarn },
	qr/^Useless use/,
);

done_testing;
