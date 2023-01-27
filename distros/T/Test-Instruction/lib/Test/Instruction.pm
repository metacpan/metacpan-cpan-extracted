package Test::Instruction;

use 5.006; use strict; use warnings; our $VERSION = '0.03';
use Compiled::Params::OO qw/cpo/;
use Types::Standard qw/Optional Str Int Bool Any CodeRef ArrayRef HashRef/;
use B qw/svref_2object/;
use Switch::Again qw/switch/;
use Test::More;
use base 'Import::Export';

our (%EX, $validate); 
BEGIN {
	%EX = (
		instruction => [qw/all/],
		instructions => [qw/all/],
		finish => [qw/all/]
	);
	$validate = cpo(
		instruction => {
			instance  => Optional->of(Any),
			meth      => Optional->of(Str),
			func      => Optional->of(CodeRef),
			args      => Optional->of(Any),
			args_list => Optional->of(Bool),
			test      => Optional->of(Str),
			expected  => Optional->of(Any),
			catch     => Optional->of(Bool),
			key       => Optional->of(Str),
			index     => Optional->of(Int),
		},
		instructions => {
			name => Str,
			run => ArrayRef,
			build => Optional->of(HashRef),
			instance => Optional->of(Any)
		},
		build => {
			class => Str,
			new => Optional->of(Str),
			args => Optional->of(Any),
			args_list => Optional->of(Bool)
		}
	);
}

sub instruction {
	my $instruction = $validate->instruction->(@_);
	my ($test_name, @test) = ("", ());
	if ( $instruction->catch ) {
		$test_name = 'catch';
		exits $instruction->test or $instruction->test('like');
		eval { _run_the_code( $instruction ) };
		@test = $@;	
	} else {
		@test = _run_the_code( $instruction );
		$test_name = shift @test;
	}

	if ( not $instruction->test ) {
		ok(0, "No 'test' passed with instruction");
		return;
	}

	switch $instruction->test, 
		"ref" => sub { 
			return is_deeply( $test[0], $instruction->expected, "${test_name} is ref - is_deeply" );

		},
		ref_key_scalar => sub {
			return ok(0, "No key passed to test - ref_key_scalar - testing - ${test_name}") 
				if (! $instruction->key );
			return is(
				$test[0]->{$instruction->key},
				$instruction->expected,
				sprintf "%s is ref - has scalar key: %s - is - %s",
				$test_name,
				$instruction->key,
				$instruction->expected
			);
		},
		ref_key_like => sub {
			return ok(0, "No key passed to test - ref_key_like - testing - ${test_name}") 
				if (! $instruction->key );
			my $like = $instruction->expected;
			return like(
				$test[0]->{$instruction->key},
				qr/$like/,
				sprintf "%s is ref - has scalar key: %s - like - %s",
				$test_name,
				$instruction->key,
				$instruction->expected
			);
		},
		ref_key_ref => sub {
			return ok(0, "No key passed to test - ref_key_ref - testing - ${test_name}") 
				if (! $instruction->key );
			return is_deeply(
				$test[0]->{$instruction->key},
				$instruction->expected,
				sprintf "%s is ref - has ref key: %s - is_deeply - ref",
				$test_name,
				$instruction->key,
			);
		},
		ref_index_scalar => sub {
			return ok(0, "No index passed to test - ref_index_scalar - testing - ${test_name}") 
				if (! defined $instruction->index );
			return is(
				$test[0]->[$instruction->index],
				$instruction->expected,
				sprintf "%s is ref - has scalar index: %s - is - %s",
				$test_name,
				$instruction->index,
				$instruction->expected
			);
		},
		ref_index_ref => sub {
			return ok(0, "No index passed to test - ref_index_ref - testing - ${test_name}") 
				if (! defined $instruction->index );
			is_deeply(
				$test[0]->[$instruction->index],
				$instruction->expected,
				sprintf "%s is ref - has ref index: %s - is_deeply - ref",
				$test_name,
				$instruction->index,
			);
		},
		ref_index_like => sub {
			return ok(0, "No index passed to test - ref_index_like - testing - ${test_name}") 
				if (! defined $instruction->index );
			my $like = $instruction->expected;	
			return like(
				$test[0]->[$instruction->index],
				qr/$like/,
				sprintf "%s is ref - has scalar index: %s - like - %s",
				$test_name,
				$instruction->index,
				$instruction->expected
			);
		},
		ref_index_obj => sub {
			return ok(0, "No index passed to test - ref_index_obj - testing - ${test_name}") 
				if (! defined $instruction->index );
			return isa_ok(
				$test[0]->[$instruction->index],
				$instruction->expected,
				sprintf "%s is ref - has obj index: %s - isa_ok - %s",
				$test_name,
				$instruction->index,
				$instruction->expected
			);
		},
		list_index_scalar => sub {
			return ok(0, "No index passed to test - list_index_scalar - testing - ${test_name}") 
				if (! defined $instruction->index );

			return is(
				$test[$instruction->index],
				$instruction->expected,
				sprintf "%s is list - has scalar index: %s - is - %s",
				$test_name,
				$instruction->index,
				$instruction->expected
			);
		},
		list_index_ref => sub {
			return ok(0, "No index passed to test - list_index_ref - testing - ${test_name}") 
				if (! defined $instruction->index );
			return is_deeply(
				$test[$instruction->index],
				$instruction->expected,
				sprintf "%s is list - has ref index: %s - is_deeply - ref",
				$test_name,
				$instruction->index,
			);
		},
		list_index_like => sub {
			return ok(0, "No index passed to test - list_index_like - testing - ${test_name}") 
				if (! defined $instruction->index );
			my $like = $instruction->expected;	
			return is(
				$test[$instruction->index],
				qr/$like/,
				sprintf "%s is list - has scalar index: %s - like - %s",
				$test_name,
				$instruction->index,
				$instruction->expected
			);
		},
		list_index_obj => sub {
			return ok(0, "No index passed to test - list_index_obj - testing - ${test_name}") 
				if (! defined $instruction->index );
			return isa_ok(
				$test[$instruction->index],
				$instruction->expected,
				sprintf "%s is list - has obj index: %s - isa_ok - %s",
				$test_name,
				$instruction->index,
				$instruction->expected
			),
		},
		list_key_scalar => sub {
			return ok(0, "No key passed to test - list_key_scalar - testing - ${test_name}") 
				if (! $instruction->key );
			return is(
				{@test}->{$instruction->key},
				$instruction->expected,
				sprintf "%s is list - has scalar key: %s - is - %s",
				$test_name,
				$instruction->key,
				$instruction->expected
			);
		},
		list_key_ref => sub {
			return ok(0, "No key passed to test - list_key_ref - testing - ${test_name}") 
				if (! $instruction->key );
			return is_deeply(
				{@test}->{$instruction->key},
				$instruction->expected,
				sprintf "%s is list - has ref key: %s - is_deeply - ref",
				$test_name,
				$instruction->key,
			);
		},
		list_key_like => sub {
			return ok(0, "No key passed to test - list_key_like - testing - ${test_name}") 
				if (! $instruction->key );
			my $like = $instruction->expected;	
			return is(
				{@test}->{$instruction->key},
				qr/$like/,
				sprintf "%s is list - has scalar key: %s - like - %s",
				$test_name,
				$instruction->key,
				$instruction->expected
			);
		},
		count => sub {
			return is(
				scalar @test,
				$instruction->expected,
				sprintf "%s is array - count - is - %s",
				$test_name,
				$instruction->expected
			);
		},
		count_ref => sub {
			return is(
				scalar @{$test[0]},
				$instruction->expected,
				sprintf "%s is ref - count - is - %s",
				$test_name,
				$instruction->expected
			);
		},
		scalar => sub {
			return is( $test[0], $instruction->expected, sprintf "%s is scalar - is - %s",
				$test_name, defined $instruction->expected ? $instruction->expected : 'undef');
		},
		hash => sub {
			return is_deeply(
				scalar @test == 1 ? $test[0] : {@test},
				$instruction->expected,
				sprintf "%s is hash - is_deeply",
				$test_name,
			);
		},
		array => sub {
			return is_deeply(
				scalar @test == 1 ? $test[0] : \@test,
				$instruction->expected,
				sprintf "%s is array - is_deeply",
				$test_name,
			);
		},
		obj => sub {
			return isa_ok(
				$test[0],
				$instruction->expected,
				sprintf "%s isa_ok - %s",
				$test_name,
				$instruction->expected
			);
		},
		code => sub {
			return is(
				ref $test[0],
				'CODE',
				sprintf "%s is a CODE block",
				$test_name
			);
		},
		code_execute => sub {
			return is_deeply(
				$test[0]->($instruction->args ? @{$instruction->args} : ()),
				$instruction->expected,
				sprintf "%s is deeply %s",
				$test_name,
				$instruction->expected
			);
		},
		like => sub {
			my $like = $instruction->expected;
			return like(
				$test[0],
				qr/$like/,
				sprintf "%s is like - %s",
				$test_name,
				$instruction->expected
			);
		},
		true => sub {
			return ok($test[0], "${test_name} is true - 1");
		},
		false => sub {
			return ok(!$test[0], "${test_name} is false - 0");
		},
		undef => sub {
			return is($test[0], undef, "${test_name} is undef");
		},
		ok => sub {
			return ok(@test, "${test_name} is ok");
		},
		skip => sub {
			return ok(1, "${test_name} - skip");
		},
		default => sub {
			ok(0, "Unknown instruction $_[0]: passed to instrcution");
			return;
		};
}

sub instructions { 
	my $instructions = $validate->instructions->(@_);

	ok(1, sprintf "instructions: %s", $instructions->name);

	my $instance = $instructions->build ? _build($instructions->build) : $instructions->instance;

	my %test_info = (
		fail => 0,
		tested => 0,
	);

	for my $instruction (@{$instructions->run}) {
		$test_info{tested}++;
		if (my $subtests = delete $instruction->{instructions}) {
			my ($test_name, $new_instance) = _run_the_code(
				$validate->instruction->(
					instance => $instance,
					%{$instruction}
				)
			);
			
			$test_info{fail}++
				unless instruction(
					instance => $new_instance,
					test => $instruction->{test},
					expected => $instruction->{expected}
				);

			instructions(
				instance => $new_instance,
				run => $subtests,
				name => sprintf "Subtest -> %s -> %s", $instructions->name, $test_name
			);
			next;
		}

		$test_info{fail}++
			unless instruction(
				instance => $instance,
				%{$instruction}
			);
	}
	
	$test_info{ok} = $test_info{fail} ? 0 : 1;
	return ok(
		$test_info{ok},
		sprintf(
			"instructions: %s - tested %d instructions - success: %d - failure: %d",
			$instructions->name,
			$test_info{tested},
			($test_info{tested} - $test_info{fail}),
			$test_info{fail}
		)
	);
}

sub finish {
	my $done_testing = done_testing(shift);
	return $done_testing;
}


sub _build {
	my $build = $validate->build->(@_);
	my $new = $build->new || 'new';
	return $build->class->$new($build->args_list ? @{ $build->args } : $build->args);
}

sub _run_the_code {
	my $instruction = shift;
	if ($instruction->meth) {
		my $meth = $instruction->meth;
		return (
			"function: ${meth}",
			$instruction->instance->$meth(
				$instruction->args_list 
					? @{ $instruction->args }
					: $instruction->args
			)
		);
	} elsif ($instruction->func) {
		my $func_name = svref_2object($instruction->func)->GV->NAME;
		return (
			"function: ${func_name}",
			$instruction->func->($instruction->args_list ? @{$instruction->args} : $instruction->args)
		);
	} elsif ($instruction->instance) {
		return ('instance', $instruction->instance); 
	}

	die(
		'instruction passed to _run_the_code must have a func, meth or instance key'
	);
}

__END__

1;

=head1 NAME

Test::Instruction - A test framework

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS

    	use Test::Instruction qw/all/;

	use Module::To::Test;

	instruction(
		test => 'true',
		func => \&Module::To::Test::true_function
	);

	instruction(
		test => 'false',
		func => \&Module::To::Test::false_function
	);

	my $obj = Module::To::Test->new();

	instruction(
		test => 'hash',
		instance => $obj,
		meth => 'method_that_returns_a_hash',
		expected => { a => 1, b => 2, c => 3 }
	);

	finish(3);

	...

	use Test::Instruction qw/all/;

	instructions(
		name => 'Checking Many Things',
		build => {
			class => 'London',
		},
		run => [
			{
				test => 'hash',
				expected => {
					booking => '66/68',
				}
			},
			{
				test => 'true',
				meth => 'true',
			},
			{
				test => 'false',
				meth => 'false',
			},
			{
				test => 'ok',
				meth => "chain",
				instructions => [
					{
						test => 'hash',
						expected => {
							paddington => "sleep"
						}
					}
				]
			}
		],
	);

	finish();

=head1 EXPORT

=head2 instruction

    instruction(
        test      => 'ok',
        instance  => Module::To::Test->new(),
        func      => 'okay',
        args      => {
            data  => '...'
        },
    );
 
=head3 test 

you can currently run the following tests.

over
 
=item ok - ok - a true value 
 
=item ref - is_deeply - expected [] or {}
 
=item scalar - is - expected '',
 
=item hash - is_deeply - expected {},
 
=item array - is_deeply - expected [],
 
=item obj - isa_ok - expected '',
 
=item like - like - '',
 
=item true - is - 1,
 
=item false - is - 0,
 
=item undef - is - undef
 
=item ref_key_scalar - is - '' (requires key)
 
=item ref_key_ref - is_deeply - [] or {} (requires key)
 
=item ref_key_like - like - ''
 
=item ref_index_scalar - is - '' (requires index)
 
=item ref_index_ref - is_deeply - [] or {} (required index)
 
=item ref_index_like - like - ''
 
=item ref_index_obj - isa_ok - ''
 
=item list_key_scalar - is - '' (requires key)
 
=item list_key_ref - is_deeply - [] or {} (requires key)
 
=item list_key_like - like - ''
 
=item list_index_scalar - is - '' (requires index)
 
=item list_index_ref - is_deeply - [] or {} (required index)
 
=item list_index_obj - isa_ok - ''
 
=item list_index_like - like - ''
 
=item count - is - ''
 
=item count_ref - is - ''
 
=item skip - ok(1)

=item code - is - 'CODE'

=item code_execute - is_deeply - ''

=back

=head3 catch
 
when you want to catch exceptions....
 
    catch => 1,
 
defaults the instruction{test} to like.
 
=head3 instance
 
    my $instance = My::Test::Module->new();
    instance => $instance,
 
=head3 meth
 
call a method from the instance
 
    instance => $instance,
    meth     => 'render'
 
=head3 func
 
    func => \&My::Test::Module::render,
 
=head3 args
 
    {} or []
 
=head3 args_list
 
    args      => [qw/one, two/],
    args_list => 1,
 
=head3 index
 
index - required when testing - ref_index_* and list_index_*
 
=head3 key
 
key - required when testing - ref_key_* and list_key_*
 
=cut

=head2 instructions

=cut

=head2 finish

=cut

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-instruction at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Instruction>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Test::Instruction

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Instruction>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Test-Instruction>

=item * Search CPAN

L<https://metacpan.org/release/Test-Instruction>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2022 by LNATION.

This is free software, licensed under:

	The Artistic License 2.0 (GPL Compatible)

=cut

1; # End of Test::Instruction
