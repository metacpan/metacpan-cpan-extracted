#!/usr/bin/env perl
use warnings;
use strict;

=head1 Synopsis

Tests for aliasing a subset of arrays using C<@_>. These tests do
not test any features of this distribution, instead they test the
documentation: L<Tie::Subset/Note>.

I have added this file to my distribution so that the code is
tested on a wide variety of systems (via CPAN Testers etc.).

=head1 Author, Copyright, and License

Copyright (c) 2018-2023 Hauke Daempfling (haukex@zero-g.net).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5 itself.

For more information see the L<Perl Artistic License|perlartistic>,
which should have been distributed with your copy of Perl.
Try the command C<perldoc perlartistic> or see
L<http://perldoc.perl.org/perlartistic.html>.

=cut

use Test::More;

## no critic (RequireTestLabels)

# aliasing
my @array = (11,22,33,44,55,66,77,88,99);
my $subset = sub { \@_ }->( @array[2..5,7,9,11] );
is_deeply $subset, [33,44,55,66,88,undef,undef] or diag explain $subset;
is @$subset, 7;
is_deeply \@array, [11,22,33,44,55,66,77,88,99,undef,undef,undef];

# Fetching
is $$subset[0], 33;
is $$subset[1], 44;
is $$subset[2], 55;
is $$subset[3], 66;
is $$subset[4], 88;
is $$subset[5], undef;
is $$subset[6], undef;
is $$subset[7], undef;
is $$subset[8], undef;
is $$subset[-1], undef;

# Storing
ok $$subset[1]=42;
is_deeply $subset, [33,42,55,66,88,undef,undef] or diag explain $subset;
is_deeply \@array, [11,22,33,42,55,66,77,88,99,undef,undef,undef];
$$subset[-1]=123;
is_deeply $subset, [33,42,55,66,88,undef,123] or diag explain $subset;
is_deeply \@array, [11,22,33,42,55,66,77,88,99,undef,undef,123];
@$subset[5,3]=(456);
is_deeply $subset, [33,42,55,undef,88,456,123] or diag explain $subset;
is_deeply \@array, [11,22,33,42,55,undef,77,88,99,456,undef,123];

$$subset[7]=999;
is_deeply $subset, [33,42,55,undef,88,456,123,999] or diag explain $subset;
is_deeply \@array, [11,22,33,42,55,undef,77,88,99,456,undef,123];
$$subset[11]=888;
is_deeply $subset, [33,42,55,undef,88,456,123,999,undef,undef,undef,888] or diag explain $subset;
is_deeply \@array, [11,22,33,42,55,undef,77,88,99,456,undef,123];

done_testing;
