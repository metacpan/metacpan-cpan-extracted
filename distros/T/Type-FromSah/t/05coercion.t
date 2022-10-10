=pod

=encoding utf-8

=head1 PURPOSE

Check that Type::FromSah handles coercion.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
use Test::More;
use Test::Requires 'Data::Sah::Coerce';
use Test::Requires 'DateTime';

use Type::FromSah -all;

my $Date = sah2type( [ "date", { "x.perl.coerce_to" => "DateTime" } ], name => 'Date' );

ok( !$Date->check( '2022-09-30' ), 'coercible value fails initial check' );

my $got = $Date->coerce( '2022-09-30' );

ok( $Date->check( $got ), 'coerced value passes check after explicit coercion' );

done_testing;
