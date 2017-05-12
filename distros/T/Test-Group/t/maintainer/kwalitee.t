#!/usr/bin/perl -w

=head1 NAME

kwalitee.t - Applies L<Test:Kwalitee> on the module.

=head1 DESCRIPTION

Code is basically copied and pasted from L<Test:Kwalitee>.  Note that you need
a tarball for this test (eg C<./Build dist>).


=cut

use Test::More;

eval { require Test::Kwalitee; Test::Kwalitee->import() };

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

