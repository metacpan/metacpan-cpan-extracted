package Test::RandomResults;

use warnings;
use strict;

use base 'Exporter';

our @EXPORT = qw(is_in in_between length_lt length_le length_eq length_ge length_gt);

=head1 NAME

Test::RandomResults - Test non-deterministic functions

=cut

our $VERSION = '0.03';

use Test::Builder;
my $Test = Test::Builder->new();
my $seed = int( 100000 * rand() ); # yes, I know this is stupid :-)
srand( $seed );
$Test->diag( "(SEED $seed)" );

=head1 DESCRIPTION

This module aims to provide ways of testing functions that are meant
to return results that are random; that is, non-deterministic
functions.

Some of the tests provided here might be easily achieved with other
testing modules. The reason why they're here is that this way users
become aware of how to test their non-deterministic functions.

=head1 NOTICE

This is a work in progress. Comments are welcome.

=head1 SYNOPSIS

  use Test::More plan => $Num_Tests;
  use Test::RandomResults;

  is_in( my_function, [ $list, $of, $items ], "result is inside list" );

  in_between( my_function, sub { $_[0] cmp $_[1] }, 1, 10, "result between 1 and 10");

  length_lt( my_function, $limit, "length less than $limit");

  length_le( my_function, $limit, "length less or equal to $limit");

  length_eq( my_function, $limit, "length equal to $limit");

  length_ge( my_function, $limit, "length greater of equal to $limit");

  length_gt( my_function, $limit, "length greater than $limit");

=head1 SPECIAL FEATURES

Whenever C<Test::RandomResults> is invoked, a new seed is generated
and outputed as diagnostics. This is done so that you can use it to
debug your code, if needed.

=head1 FUNCTIONS

=head2 is_in

Tests if an element belongs to an array.

  is_in( my_function, [1, 2, 3], 'either 1, 2 or 3');

=cut

sub is_in ($@;$) {
  my ($item, $list, $desc) = @_;

  return (
    $Test->ok( scalar (grep { $item eq $_ } @$list) , $desc ) ||
    $Test->diag( "        $item is not in (@$list)" )
  );
}

=head2 in_between

Tests if an element is within two boundaries.

The second parameter to this function is what it uses to do the
comparisons.

To compare strings:

  in_between( my_function, { $_[0] cmp $_[1] }, "aaa", "zzz",
              'result is between "aaa" and "zzz"' );

To compare numbers:

  in_between( my_function, { $_[0] <=> $_[1] }, 1, 10, 'result is between 1 and 10' );

To compare something else:

  in_between( my_function, &your_function_here, $lower_boundary, $upper_boundary,
              'result is between boundaries' );

As you can see, the function should use $_[0] and $_[1] to do the comparison.
As with <=> and cmp, the function should return 1, 0 or -1 depending on whether
the first argument ($_[0]) is greater, equal to, or less than the second one
($_[1]).

C<in_between> swaps the lower and upper limits, if need be (this means
that checking whether a value is between 1 and 10 is the same as
checking between 10 and 1).

=cut

sub in_between ($$$$;$) {
  my ($item, $function, $lower, $upper, $desc) = @_;

  if ( $function->( $lower, $upper ) > 0 ) {
    ($lower, $upper) = ($upper, $lower);
  }

  return (
    $Test->ok( ( $function->($item,$lower) > -1 and
                 $function->($item,$upper) <  1 ) , $desc ) ||
    $Test->diag( "        $item not between $lower and $upper" )
  );
}

=head2 length_lt

Tests if length is less than a limit.

  length_lt( my_function, $limit, "length less than $limit");

=cut

sub length_lt ($$;$) {
  my ($item, $limit, $desc) = @_;

  return (
    $Test->ok( _length('<', $item, $limit), $desc ) ||
    $Test->diag( "        length of $item not less than $limit" )
  );
}

=head2 length_le

Tests if length is less or equal to a limit.

  length_le( my_function, $limit, "length less or equal to $limit");

=cut

sub length_le ($$;$) {
  my ($item, $limit, $desc) = @_;

  return (
    $Test->ok( _length('<=', $item, $limit), $desc ) ||
    $Test->diag( "        length of $item not less than or equal to $limit" )
  );
}

=head2 length_eq

Tests if length is equal to a limit.

  length_eq( my_function, $limit, "length equal to $limit");

=cut

sub length_eq ($$;$) {
  my ($item, $limit, $desc) = @_;

  return (
    $Test->ok( _length('==', $item, $limit), $desc ) ||
    $Test->diag( "        length of $item not equal to $limit" )
  );
}

=head2 length_ge

Tests if length is greater of equal to a limit.

  length_ge( my_function, $limit, "length greater of equal to $limit");

=cut

sub length_ge ($$;$) {
  my ($item, $limit, $desc) = @_;

  return (
    $Test->ok( _length('>=', $item, $limit), $desc ) ||
    $Test->diag( "        length of $item not greater than or equal to $limit" )
  );
}

=head2 length_gt

Tests if length is greater than a limit.

  length_gt( my_function, $limit, "length greater than $limit");

=cut

sub length_gt ($$;$) {
  my ($item, $limit, $desc) = @_;

  return (
    $Test->ok( _length('>', $item, $limit), $desc ) ||
    $Test->diag( "        length of $item not greater than $limit" )
  );
}

#

sub _length ($$$) {
  my ($op, $item, $limit) = @_;

  my $length = length $item;

  return eval "$length $op $limit";
}

=head1 TO DO

* Check if N results of a function are evenly_distributed

* Allow the user to choose the seed when invoking C<Test::RandomResults>

=head1 AUTHOR

Jose Castro, C<< <cog@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-randomresults@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Test::RandomResults
