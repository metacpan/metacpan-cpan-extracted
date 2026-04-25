package Test::IsAny;
use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

Test::IsAny - check if a value is any of the given values

=head1 SYNOPSIS

  use strict;
  use warnings;

  use Test::More tests => 1;
  use Test::IsAny qw(is_any);

  my $result = 42; # this is the result of the Application Under Test
  my @expected = (10, 71, 23, 42);
  is_any($result, \@expected, 'The right anwser');

=head1 DESCRIPTION

The primary goal of this function and module was to teach how you can create your own test function.
See the Perl Testing book (and course) on the L<Perl Maven|https://perlmaven.com/> site.


=head1 AUTHOR

L<Gabor Szabo|http://szabgab.com/>

=head1 COPYRIGHT

Copyright 2026 Gabor Szabo, All Rights Reserved.

You may use, modify, and distribute this package under the
same terms as Perl itself.

=cut

use Exporter qw(import);
our @EXPORT_OK = qw(is_any);

use List::MoreUtils qw(any);

use Test::Builder::Module;

sub is_any {
	my ( $actual, $expected, $name ) = @_;
	$name ||= '';

	my $Test = Test::Builder::Module->builder;

	$Test->ok( ( any { $_ eq $actual } @$expected ), $name )
		or $Test->diag( "Received: $actual\nExpected:\n" . join "",
		map {"         $_\n"} @$expected );
}

1;

