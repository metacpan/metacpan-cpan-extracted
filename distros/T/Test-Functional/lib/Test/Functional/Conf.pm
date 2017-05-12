package Test::Functional::Conf;

use warnings FATAL => 'all';
use strict;

our $VERSION = '0.06';

use Carp;
use Exporter;

my %SETTINGS = (
    unstable => 0,
    fastout  => 0,
);

sub import {
    my ($class, @args) = @_;
    for(my $i=0; $i < scalar(@args); $i += 2) {
        my ($key, $value) = @args[$i,$i + 1];
        croak "invalid setting '$key'" unless exists($SETTINGS{$key});
        $SETTINGS{$key} = $value;
    }
}

sub unstable { return $SETTINGS{unstable} }
sub fastout { return $SETTINGS{fastout} }

=head1 NAME

Test::Functional::Conf - Run-time configure for Test::Functional

=head1 SYNOPSIS

  # run extra "in-development" tests
  perl -MTest::Functional::Conf=unstable,1 some-test.t

  # stop at first test failure
  perl -MTest::Functional::Conf=fastout,1 some-test.t

  # find first test failure (including unstable tests)
  perl -MTest::Functional::Conf=fastout,1,unstable,1 some-test.t

=head1 DESCRIPTION

This package's only function is to allow a user to toggle various modes of
Test::Functional. The synopsis provides the general idea. The specific features
that are currently available are:

=over

=item * unstable (boolean): run test which are under construction (signified by
using I<notest()> rather than I<test()>.

=item * fastout (boolean): halt the test at the first failure.

=back

For more information, see L<Test::Functional>.

=head1 AUTHOR

Erik Osheim C<< <erik at osheim.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Erik Osheim, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
