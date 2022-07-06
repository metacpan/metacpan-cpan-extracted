package Test::JSON::Type;

use base qw(Test::Builder::Module);
use strict;
use warnings;

use Cpanel::JSON::XS;
use Cpanel::JSON::XS::Type;
use English;
use Error::Pure qw(err);
use Readonly;
use Test::Differences qw(eq_or_diff);

Readonly::Array our @EXPORT => qw(cmp_json_types is_json_type);

our $VERSION = 0.04;

sub cmp_json_types {
	my ($json, $json_expected, $test_name) = @_;

	if (! defined $json) {
		err 'JSON string to compare is required.';
	}
	if (! defined $json_expected) {
		err 'Expected JSON string to compare is required.';
	}

	my $test = __PACKAGE__->builder;
	my $json_obj = Cpanel::JSON::XS->new;

	my $type_hr;
	eval {
		$json_obj->decode($json, $type_hr);
	};
	if ($EVAL_ERROR) {
		err "JSON string isn't valid.",
			'Error', $EVAL_ERROR,
		;
	}
	_readable_types($type_hr);
	my $type_expected_hr;
	eval {
		$json_obj->decode($json_expected, $type_expected_hr);
	};
	if ($EVAL_ERROR) {
		err "Expected JSON string isn't valid.",
			'Error', $EVAL_ERROR,
		;
	}
	_readable_types($type_expected_hr);

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	return eq_or_diff($type_hr, $type_expected_hr, $test_name);
}

sub is_json_type {
	my ($json, $type_expected_hr, $test_name) = @_;

	if (! defined $json) {
		err 'JSON string to compare is required.';
	}

	my $test = __PACKAGE__->builder;
	my $json_obj = Cpanel::JSON::XS->new;

	my $type_hr;
	my $json_hr = eval {
		$json_obj->decode($json, $type_hr);
	};
	if ($EVAL_ERROR) {
		err "JSON string isn't valid.",
			'Error', $EVAL_ERROR,
		;
	}
	_readable_types($type_hr);

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	eval {
		$json_obj->encode($json_hr, $type_expected_hr);
	};
	if ($EVAL_ERROR) {
		$test->ok(0, $test_name);
		$test->diag('Error: '.$EVAL_ERROR);
		return;
	}

	$test->ok(1, $test_name);
	return 1;
}

sub _change_type {
	my $value_sr = shift;

	if (${$value_sr} == JSON_TYPE_BOOL) {
		${$value_sr} = 'JSON_TYPE_BOOL';
	} elsif (${$value_sr} == JSON_TYPE_INT) {
		${$value_sr} = 'JSON_TYPE_INT';
	} elsif (${$value_sr} == JSON_TYPE_FLOAT) {
		${$value_sr} = 'JSON_TYPE_FLOAT';
	} elsif (${$value_sr} == JSON_TYPE_STRING) {
		${$value_sr} = 'JSON_TYPE_STRING';
	} elsif (${$value_sr} == JSON_TYPE_NULL) {
		${$value_sr} = 'JSON_TYPE_NULL';
	} else {
		err "Unsupported value '${$value_sr}'.";
	}

	return;
}

sub _readable_types {
	my $type_r = shift;

	if (ref $type_r eq 'HASH') {
		foreach my $sub_key (keys %{$type_r}) {
			if (ref $type_r->{$sub_key}) {
				_readable_types($type_r->{$sub_key});
			} else {
				_readable_types(\$type_r->{$sub_key});
			}
		}
	} elsif (ref $type_r eq 'ARRAY') {
		foreach my $sub_type (@{$type_r}) {
			if (ref $sub_type) {
				_readable_types($sub_type);
			} else {
				_readable_types(\$sub_type);
			}
		}
	} elsif (ref $type_r eq 'SCALAR') {
		_change_type($type_r);
	} else {
		err "Unsupported value '$type_r'.";
	}

	return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Test::JSON::Type - Test JSON data with types.

=head1 SYNOPSIS

 use Test::JSON::Type;

 cmp_json_types($json, $json_expected, $test_name);
 is_json_type($json, $expected_type_hr, $test_name);

=head1 SUBROUTINES

=head2 C<cmp_json_types>

 cmp_json_types($json, $json_expected, $test_name);

This decodes C<$json> and C<$json_expected> JSON strings to Perl structure and
return data type structure defined by L<Cpanel::JSON::XS::Type>.
And compare these structures, if are same.

Result is success or failure of this comparison. In case of failure print
difference in test.

=head2 C<is_json_type>

 is_json_type($json, $expected_type_hr, $test_name);

This decoded C<$json> JSON string to Perl structure and return data type
structure defined by L<Cpanel::JSON::XS::Type>.
Compare this structure with C<$expected_type_hr>, if are same.

Result is success or failure of this comparison. In case of failure print
difference in test.

=head1 ERRORS

 cmp_json_types():
         JSON string isn't valid.
                 Error: %s
         JSON string to compare is required.
         Expected JSON string isn't valid.
                 Error: %s
         Expected JSON string to compare is required.
 is_json_type():
         JSON string isn't valid.
                 Error: %s
         JSON string to compare is required.

=head1 EXAMPLE1

 use strict;
 use warnings;

 use Test::JSON::Type;
 use Test::More 'tests' => 2;

 my $json_blank1 = '{}';
 my $json_blank2 = '{}';
 cmp_json_types($json_blank1, $json_blank2, 'Blank JSON strings.');

 my $json_struct1 = <<'END';
 {
   "bool": true,
   "float": 0.23,
   "int": 1,
   "null": null,
   "string": "bar"
 }
 END
 my $json_struct2 = <<'END';
 {
   "bool": false,
   "float": 1.23,
   "int": 2,
   "null": null,
   "string": "foo"
 }
 END
 cmp_json_types($json_struct1, $json_struct2, 'Structured JSON strings.');

 # Output:
 # 1..2
 # ok 1 - Blank JSON strings.
 # ok 2 - Structured JSON strings.

=head1 EXAMPLE2

 use strict;
 use warnings;

 use Test::JSON::Type;
 use Test::More 'tests' => 1;

 my $json_struct_err1 = <<'END';
 {
   "int": 1,
   "string": "1"
 }
 END
 my $json_struct_err2 = <<'END';
 {
   "int": 1,
   "string": 1
 }
 END
 cmp_json_types($json_struct_err1, $json_struct_err2, 'Structured JSON strings with error.');

 # Output:
 # 1..1
 # not ok 1 - Structured JSON strings with error.
 # #   Failed test 'Structured JSON strings with error.'
 # #   at ./ex2.pl line 21.
 # # +----+--------------------------------+-----------------------------+
 # # | Elt|Got                             |Expected                     |
 # # +----+--------------------------------+-----------------------------+
 # # |   0|{                               |{                            |
 # # |   1|  int => 'JSON_TYPE_INT',       |  int => 'JSON_TYPE_INT',    |
 # # *   2|  string => 'JSON_TYPE_STRING'  |  string => 'JSON_TYPE_INT'  *
 # # |   3|}                               |}                            |
 # # +----+--------------------------------+-----------------------------+
 # # Looks like you failed 1 test of 1.

=head1 EXAMPLE3

 use strict;
 use warnings;

 use Test::JSON::Type;
 use Test::More 'tests' => 1;

 my $json_struct_err1 = <<'END';
 {
   "int": 1,
   "array": ["1", 1]
 }
 END
 my $json_struct_err2 = <<'END';
 {
   "int": 1,
   "array": 1
 }
 END
 cmp_json_types($json_struct_err1, $json_struct_err2, 'Structured JSON strings with error.');

 # Output:
 # 1..1
 # not ok 1 - Structured JSON strings with error.
 # #   Failed test 'Structured JSON strings with error.'
 # #   at ./ex3.pl line 21.
 # # +----+--------------------------+----+-----------------------------+
 # # | Elt|Got                       | Elt|Expected                     |
 # # +----+--------------------------+----+-----------------------------+
 # # |   0|{                         |   0|{                            |
 # # *   1|  array => [              *   1|  array => 'JSON_TYPE_INT',  *
 # # *   2|    'JSON_TYPE_STRING',   *    |                             |
 # # *   3|    'JSON_TYPE_INT'       *    |                             |
 # # *   4|  ],                      *    |                             |
 # # |   5|  int => 'JSON_TYPE_INT'  |   2|  int => 'JSON_TYPE_INT'     |
 # # |   6|}                         |   3|}                            |
 # # +----+--------------------------+----+-----------------------------+
 # # Looks like you failed 1 test of 1.

=head1 EXAMPLE4

 use strict;
 use warnings;

 use Cpanel::JSON::XS::Type;
 use Test::JSON::Type;
 use Test::More 'tests' => 2;

 my $json_struct1 = <<'END';
 {
   "bool": true,
   "float": 0.23,
   "int": 1,
   "null": null,
   "string": "bar"
 }
 END
 my $json_struct2 = <<'END';
 {
   "bool": false,
   "float": 1.23,
   "int": 2,
   "null": null,
   "string": "foo"
 }
 END
 my $expected_type_hr = {
   'bool' => JSON_TYPE_BOOL,
   'float' => JSON_TYPE_FLOAT,
   'int' => JSON_TYPE_INT,
   'null' => JSON_TYPE_NULL,
   'string' => JSON_TYPE_STRING,
 };
 is_json_type($json_struct1, $expected_type_hr, 'Test JSON type #1.');
 is_json_type($json_struct2, $expected_type_hr, 'Test JSON type #2.');

 # Output:
 # 1..2
 # ok 1 - Test JSON type \#1.
 # ok 2 - Test JSON type \#2.

=head1 EXAMPLE5

 use strict;
 use warnings;

 use Cpanel::JSON::XS::Type;
 use Test::JSON::Type;
 use Test::More 'tests' => 2;

 my $json_struct = <<'END';
 {
   "array": [1,2,3]
 }
 END
 my $expected_type1_hr = {
   'array' => json_type_arrayof(JSON_TYPE_INT),
 };
 my $expected_type2_hr = {
   'array' => [
     JSON_TYPE_INT,
     JSON_TYPE_INT,
     JSON_TYPE_INT,
   ],
 };
 is_json_type($json_struct, $expected_type1_hr, 'Test JSON type (multiple integers).');
 is_json_type($json_struct, $expected_type2_hr, 'Test JSON type (three integers)');

 # Output:
 # 1..2
 # ok 1 - Test JSON type (multiple integers).
 # ok 2 - Test JSON type (three integers)

=head1 DEPENDENCIES

L<Cpanel::JSON::XS>,
L<Cpanel::JSON::XS::Type>,
L<English>,
L<Error::Pure>,
L<Readonly>,
L<Test::Builder::Module>,
L<Test::Differences>.

=head1 SEE ALSO

=over

=item L<Test::JSON>

Test JSON data

=item L<Test::JSON::More>

JSON Test Utility

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/Test-JSON-Type>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2021-2022 Michal Josef Špaček

BSD 2-Clause License

=head1 VERSION

0.04

=cut
