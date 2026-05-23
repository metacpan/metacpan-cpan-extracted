package Test::Returns;

use strict;
use warnings;

use parent 'Exporter';

# TODO: add a returns_undef function
# e.g.
# returns_undef {
    # $sc->_find_match({});
# } '_find_match returns undef when no interactions exist';
#

use Test::Builder;
use Return::Set qw(set_return);

our @EXPORT = qw(returns_ok returns_not_ok returns_is returns_isnt);

my $Test = Test::Builder->new();

=head1 NAME

Test::Returns - Verify that a method's output agrees with its specification

=head1 SYNOPSIS

    use Test::More;
    use Test::Returns;

    returns_ok(42, { type => 'integer' }, 'Returns valid integer');
    returns_ok([], { type => 'arrayref' }, 'Returns valid arrayref');
    returns_not_ok("bad", { type => 'arrayref' }, 'Fails (expected arrayref)');

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 DESCRIPTION

Exports the function C<returns_ok>, which asserts that a value satisfies a schema as defined in L<Params::Validate::Strict>.
Integrates with L<Test::Builder> for use alongside L<Test::Most> and friends.

=head1	METHODS

=head2 returns_is($value, $schema, $test_name)

Passes if C<$value> satisfies C<$schema> using C<Return::Set>.
Fails otherwise.

C<$schema> is passed directly to L<Return::Set> and on to L<Params::Validate::Strict>.
As a convenience, C<type =E<gt> 'array'> is accepted as a synonym for
C<type =E<gt> 'arrayref'>: because a bare Perl array cannot be stored as a hash
value, L<Params::Validate::Strict> only defines the C<arrayref> type, but callers
may capture a list-returning function as an arrayref and validate it with
C<type =E<gt> 'array'>.

Schema keys prefixed with C<_> (such as C<_error_return> and C<_error_handling>
as emitted by L<App::Test::Generator>) are passed through unchanged;
L<Params::Validate::Strict> ignores unknown keys in a rule hash.

=cut

sub returns_is {
	my ($value, $schema, $test_name) = @_;

	# Params::Validate::Strict only knows 'arrayref', not 'array', because a bare
	# array cannot be stored as a hash value in Perl.  Accept 'array' as a synonym.
	my $wanted_array = ref($schema) eq 'HASH' && (($schema->{'type'} // '') eq 'array');
	if($wanted_array) {
		$schema = { %{$schema}, type => 'arrayref' };
	}

	my $ok;
	my $error;

	eval {
		if(defined($value)) {
			$ok = set_return($value, $schema) eq $value;
		} else {
			set_return(undef, $schema);
			$ok = 1;
		}
		1;
	} or do {
		$error = $@;
		$ok = 0;
	};

	$test_name ||= 'Value matches schema';

	if($ok) {
		$Test->ok(1, $test_name);
	} else {
		$Test->ok(0, $test_name);
		if($wanted_array && defined($value) && !ref($value)) {
			$Test->diag("Expected an arrayref for type 'array' but got non-reference '$value'");
			$Test->diag('If the function returns a list, capture it as: my @r = func(); returns_ok(\@r, ...)');
		} else {
			$Test->diag("Validation failed: $error");
		}
	}

	return $ok;
}

=head2	returns_isnt($value, $schema, $test_name)

Opposite of C<returns_is>: passes if C<$value> does B<not> satisfy C<$schema>.

Accepts C<type =E<gt> 'array'> as a synonym for C<type =E<gt> 'arrayref'>, for
the same reasons as C<returns_is>.

=cut

sub returns_isnt
{
	my ($value, $schema, $test_name) = @_;

	if(ref($schema) eq 'HASH' && (($schema->{'type'} // '') eq 'array')) {
		$schema = { %{$schema}, type => 'arrayref' };
	}

	my $ok;

	eval {
		$ok = defined(set_return($value, $schema));
	} or do {
		$ok = 0;
	};

	$test_name ||= 'Value does not match schema';

	if($ok) {
		$Test->ok(0, $test_name);	# Value matched schema — test fails
	} else {
		$Test->ok(1, $test_name);	# Value did not match — test passes
	}

	return !$ok;
}

=head2 returns_ok($value, $schema, $test_name)

Alias for C<returns_is>.
Provided for naming symmetry and clarity.

=cut

sub returns_ok
{
	return returns_is(@_);
}

=head2	returns_not_ok

Synonym of returns_isnt

=cut

sub returns_not_ok
{
	return returns_isnt(@_);
}

=head1 AUTHOR

Nigel Horne <njh at nigelhorne.com>

=head1	SEE ALSO

L<Test::Builder>, L<Return::Set>, L<Params::Validate::Strict>

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 LICENCE AND COPYRIGHT

Copyright 2025-2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
