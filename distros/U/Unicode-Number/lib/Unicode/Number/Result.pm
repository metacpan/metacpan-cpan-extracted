package Unicode::Number::Result;
$Unicode::Number::Result::VERSION = '0.009';
use strict;
use warnings;

sub _new {
	my ($class, $str) = @_;
	bless \$str, $class;
}


sub to_string {
	my ($self) = @_;
	return "$$self";
}

sub to_numeric {
	my ($self) = @_;
	return 0+$$self;
}

sub to_bigint {
	my ($self) = @_;
	eval {
		require Math::BigInt;
		return Math::BigInt->new($self->to_string);
	} or die $@;
}

1;

# ABSTRACT: class to obtain different representations of a string to integer conversion

__END__

=pod

=encoding UTF-8

=head1 NAME

Unicode::Number::Result - class to obtain different representations of a string to integer conversion

=head1 VERSION

version 0.009

=head1 SYNOPSIS

  use Unicode::Number;
  use Math::BigInt;
  use v5.14;

  say Unicode::Number->new->string_to_number('Western', '123')->to_bigint;

=head1 DESCRIPTION

This class is used to wrap around the results of a string to number conversion
from the L<string_to_number|Unicode::Number/string_to_number> method in
L<Unicode::Number>.

=head1 METHODS

=head2 to_string

C<to_string()>

Returns a string that represents the result.

=head2 to_numeric

C<to_numeric()>

Returns an integer that numifies the result.

=head2 to_bigint

C<to_bigint()>

Returns a L<Math::BigInt> of the result.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
