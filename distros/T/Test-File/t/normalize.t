use Test::More;

use File::Spec;

use_ok( 'Test::File' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it when it should work
subtest file_spec_unix => sub {
	my $module = 'File::Spec::Unix';
	use_ok( $module );
	local @File::Spec::ISA = ( $module );

	my $file       = '/foo/bar/baz';
	my $normalized = Test::File::_normalize( $file );

	is( $normalized, $file, "Normalize gives same path for unix" );
	};

subtest file_spec_win32 => sub {
	my $module = 'File::Spec::Win32';
	use_ok( $module );
	local @File::Spec::ISA = ( $module );

	my $file       = '/foo/bar/baz';
	my $normalized = Test::File::_normalize( $file );

	isnt( $normalized, $file, "Normalize gives different path for Win32" );
	is(   $normalized, '\foo\bar\baz', "Normalize gives right path for Win32" );
	};

subtest file_spec_mac => sub {
	my $module = 'File::Spec::Mac';
	use_ok( $module );
	local @File::Spec::ISA = ( $module );

	my $file       = '/foo/bar/baz';
	my $normalized = Test::File::_normalize( $file );

	isnt( $normalized, $file, "Normalize gives different path for Mac" );
	is( $normalized, 'foo:bar:baz', "Normalize gives right path for Mac" );
	};

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Try it when it shouldn't work
subtest normalize_undef => sub {
	my $normalized = Test::File::_normalize( undef );
	ok( ! defined $normalized, "Passing undef fails" );
	};

subtest normalize_empty => sub {
	my $normalized = Test::File::_normalize( '' );
	ok( defined $normalized, "Passing empty string returns defined value" );
	is( $normalized, '', "Passing empty string returns empty string" );
	ok( ! $normalized, "Passing empty string fails" );
	};

subtest normalize_empty => sub {
	my $normalized = Test::File::_normalize();
	ok( ! defined $normalized, "Passing nothing fails" );
	};

done_testing();
