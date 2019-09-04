=pod

=encoding utf-8

=head1 PURPOSE

Bug reported by Ovid where Type::Tiny::XS checks to see if a value is
an integer by checking if the pIOK flag is set. But this can be set on
non-integer numbers after they've been cast to an integer elsewhere.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2019 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use strict;
use warnings;
no warnings 'void';
use Test::More;
use Type::Tiny::XS;

my $phi = 1.618;

my $isint = Type::Tiny::XS::get_coderef_for('Int');

is ref($isint), 'CODE';

ok not $isint->($phi);

int($phi);

ok not $isint->($phi);

done_testing;
