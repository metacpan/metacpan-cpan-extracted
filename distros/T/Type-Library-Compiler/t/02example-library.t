=pod

=encoding utf-8

=head1 PURPOSE

Test that Type::Library::Compiler works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Test::Requires { 'Types::Standard' => '1.014' };

use Type::Library::Compiler;

my $compiler = 'Type::Library::Compiler'->new(
	destination_module => 'Local::Library1',
	types => {
		String  => Types::Standard::Str,
		Integer => Types::Standard::Int,
		Number  => Types::Standard::Num,
		Array   => Types::Standard::ArrayRef,
		Hash    => Types::Standard::HashRef,
		Null    => Types::Standard::Undef,
		Object  => Types::Standard::Object,
		Any     => Types::Standard::Any,
		UA      => Types::Standard::InstanceOf[ 'HTTP::Tiny' ],
	},
);

{
	my $code = $compiler->compile_to_string;
	note( $code );
	local $@;
	eval( $code ) or die( $@ );
}

isa_ok( 'Local::Library1', 'Exporter' );

my $String = Local::Library1::String();

ok   $String->check( ""      ), 'passing type check 1';
ok   $String->check( "Hello" ), 'passing type check 2';
ok ! $String->check( []      ), 'failing type check';

ok   Local::Library1::assert_Any( 1 ), 'assert_Any( true )';
ok ! Local::Library1::assert_Any( 0 ), 'assert_Any( false )';

is(
	$Local::Library1::EXPORT_TAGS{'String'},
	[ qw( String is_String assert_String ) ],
	q[$EXPORT_TAGS{'String'}],
);

is(
	$Local::Library1::EXPORT_TAGS{'types'},
	[ sort qw( Any Integer String Number Array Hash Object Null UA ) ],
	q[$EXPORT_TAGS{'types'}],
);

is(
	$String->to_TypeTiny->{uniq},
	Types::Standard::Str->{uniq},
	'Can upgrade to Type::Tiny',
);

is(
	"$String",
	"String",
	'String overload',
);

ok(
	!!$String,
	'Bool overload',
);

is(
	$String->( "Hello" ),
	"Hello",
	'Coderef overload',
);

like(
	do { local $@; eval { $String->( [] ) }; $@ },
	qr/did not pass type constraint/,
	'Coderef overload (failing)',
);

my $tt = Local::Library1::UA()->to_TypeTiny;
ok   $tt->check( bless [], 'HTTP::Tiny' ), 'to_TypeTiny of anon type constraint 1';
ok ! $tt->check( [] ), 'to_TypeTiny of anon type constraint 2';

my $union = Local::Library1::Integer() | Local::Library1::Hash();
ok   $union->check( 42 ), 'Integer | Hash - 42';
ok   $union->check( {} ), 'Integer | Hash - {}';
ok ! $union->check( [] ), 'Integer | Hash - []';
ok ! $union->check( '' ), 'Integer | Hash - ""';

done_testing;
