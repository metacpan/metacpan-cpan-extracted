package Test::Group::NoWarnings;
use strict;
use warnings;

=head1 NAME

Test::Group::NoWarnings - turn warnings into test failures

=head1 SYNOPSIS

  use Test::Group;
  use Test::Group::NoWarnings;

  next_test_nowarnings();

  test mytest => sub {
      # ...
  };

=head1 DESCRIPTION

This module is an extension for L<Test::Group>.  It allows you to
trap warnings generated during a test group and convert them to
test failures.

If you are not already familiar with L<Test::Group> now would be
a good time to go take a look.

See also L<Test::NoWarnings>, which does something similar for the
test script as a whole rather than for a particular group.

=head1 EXPORTS

The following function is exported by default.

=head2 next_test_nowarnings ()

Causes warnings to be trapped for the next test group.

=cut

use Exporter;
use vars qw(@ISA @EXPORT $VERSION);
@ISA     = qw(Exporter);
@EXPORT  = qw(next_test_nowarnings);
$VERSION = '0.01';

use Test::Builder;
use Test::Group (); # keep this namespace clean

sub next_test_nowarnings () {
    Test::Group::next_test_plugin {
        my $next = shift;

        my @warn;
        {
            local $SIG{__WARN__} = sub { push @warn, shift };
            $next->();
        }

        my $T = Test::Builder->new;
        $T->ok(!@warn, "no warnings");
        foreach my $warn (@warn) {
            chomp $warn;
            $T->diag("WARNING: [$warn]");
        }
    };
}

=head1 SEE ALSO

L<Test::Group>, L<Test::NoWarnings>

=head1 AUTHORS

Nick Cleaton <ncleaton@cpan.org>

Dominique Quatravaux <domq@cpan.org>

=head1 LICENSE

Copyright (c) 2009 by Nick Cleaton and Dominique Quatravaux

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
