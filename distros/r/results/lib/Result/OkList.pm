use 5.014;
use strict;
use warnings;

use Result::Trait ();

package Result::OkList;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.006';

use parent qw( Result::Ok );

'overload'->import( 'Result::Trait'->__OVERLOAD_ARGS__( 'ok_list', '_peek' ) );

sub unwrap {
	my ( $self ) = @_;
	@_ == 1 && wantarray
		or Carp::croak( 'Usage: $result->unwrap() in list context' );

	$self->[0] = !!1;

	@{ $self->[1] };
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Result::OkList - a class for non-error results which must be unwrapped in list context

=head1 DESCRIPTION

Refer to the C<ok_list> function in L<results> to find out how to construct
instances of this class. Refer to L<Result::Trait> for the API documentation
for objects of this class.

=head1 BUGS

Please report any bugs to
L<https://github.com/tobyink/p5-results/issues>.

=head1 SEE ALSO

L<result>, L<Result::Trait>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
