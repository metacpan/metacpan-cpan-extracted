use strict;
use warnings;
use Test::More;

eval { require Capture::Tiny };
plan skip_all => 'Capture::Tiny not found' if $@;

plan tests => 8;

my $expected_stderr = '';

# first capture the output of a program that does *not* call eq_pdl()
# this is to work around warnings that might be emitted by other modules (e.g.,
# File::Map on some platforms complaining about the :all tag)
{
	my $rc;
	my( $stdout, $stderr ) = Capture::Tiny::capture( sub {
			my @cmd = ( $^X, '-Ilib', '-MTest::PDL=eq_pdl', '-e1' );
			$rc = system @cmd;
		} );
	cmp_ok $rc, '==', 0, 'system() succeeded';
	is $stdout, '', 'no output on stdout';
	$expected_stderr = $stderr;
}

# test that eq_pdl() doesn't produce any output so it can safely be used in non-test code
{
	my $rc;
	my( $stdout, $stderr ) = Capture::Tiny::capture( sub {
			my @cmd = ( $^X, '-Ilib', '-MTest::PDL=eq_pdl', '-e', 'eq_pdl(3,4)' );
			$rc = system @cmd;
		} );
	cmp_ok $rc, '==', 0, 'system() succeeded';
	is $stdout, '', 'eq_pdl() does not produce output on stdout';
	is $stderr, $expected_stderr, 'eq_pdl() does not produce output on stderr';
}

# test that eq_pdl_diag() doesn't produce any output so it can safely be used in non-test code
{
	my $rc;
	my( $stdout, $stderr ) = Capture::Tiny::capture( sub {
			my @cmd = ( $^X, '-Ilib', '-MTest::PDL=eq_pdl_diag', '-e', 'eq_pdl_diag(3,4)' );
			$rc = system @cmd;
		} );
	cmp_ok $rc, '==', 0, 'system() succeeded';
	is $stdout, '', 'eq_pdl_diag() does not produce output on stdout';
	is $stderr, $expected_stderr, 'eq_pdl_diag() does not produce output on stderr';
}
