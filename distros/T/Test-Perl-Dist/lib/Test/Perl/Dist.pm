package Test::Perl::Dist;

use strict;
use warnings;
use 5.008001;
use Test::More 0.88 import => ['!done_testing'];
use Test::Builder;
use parent qw( Exporter );
use English qw( -no_match_vars );
use Scalar::Util qw( blessed );
use LWP::Online qw( :skip_all );
use File::Spec::Functions qw( :ALL );
use File::Path qw();
use File::Remove qw();
use Win32 qw();
use URI qw();

our @EXPORT =
  qw(test_run_dist test_verify_files_short test_verify_files_medium
  test_verify_files_long test_verify_portability test_cleanup);
push @EXPORT, @Test::More::EXPORT;

our $VERSION = '0.300';
$VERSION =~ s/_//ms;

my $tests_completed = 0;



#####################################################################
# Default Paths

sub _make_path {
	my $dir = rel2abs( catdir( curdir(), @_ ) );
	if ( not -d $dir ) {
		File::Path::mkpath($dir);
	}
	ok( -d $dir, 'Created ' . $dir );
	$tests_completed++;
	return $dir;
}

sub _remake_path {
	my $dir = rel2abs( catdir( curdir(), @_ ) );
	if ( -d $dir ) {
		File::Remove::remove( \1, $dir );
	}
	File::Path::mkpath($dir);
	ok( -d $dir, 'Created ' . $dir );
	$tests_completed++;
	return $dir;
}

sub _paths {
	my $class    = shift;
	my $subpath  = shift || q{};
	my $testpath = shift || 't';

	# Create base and download directory so we can do a
	# GetShortPathName on it.
	my $basedir  = rel2abs( catdir( $testpath, "tmp$subpath" ) );
	my $download = rel2abs( catdir( $testpath, 'download' ) );

	if ( $basedir =~ m{\s}sm ) {
		plan( skip_all =>
			  'Cannot test successfully in a test directory with spaces' );
	}

	if ( not -d $basedir ) {
		File::Path::mkpath($basedir);
	}
	if ( not -d $download ) {
		File::Path::mkpath($download);
	}
	diag("Test base directory: $basedir");

	# Make or remake the subpaths
	my $output_dir = _remake_path( catdir( $basedir, 'output' ) );
	my $image_dir  = _remake_path( catdir( $basedir, 'image' ) );
	my $download_dir = _make_path($download);
	my $fragment_dir = _remake_path( catdir( $basedir, 'fragments' ) );
	my $build_dir    = _remake_path( catdir( $basedir, 'build' ) );
	my $tempenv_dir  = _remake_path( catdir( $basedir, 'tempdir' ) );
	return (
		output_dir   => $output_dir,
		image_dir    => $image_dir,
		download_dir => $download_dir,
		build_dir    => $build_dir,
		fragment_dir => $fragment_dir,
		temp_dir     => $basedir,
		tempenv_dir  => $tempenv_dir,
	);
} ## end sub _paths

sub _cpan_release {
	my $class = shift;
	if ( defined $ENV{PERL_RELEASE_TEST_PERLDIST_CPAN} ) {
		return (
			cpan => URI->new( $ENV{PERL_RELEASE_TEST_PERLDIST_CPAN} ) );
	} else {
		return ();
	}
}

sub _forceperl {
	my $class = shift;
	if ( defined $ENV{PERL_RELEASE_TEST_FORCEPERL} ) {
		return ( forceperl => 1 );
	} else {
		return ();
	}
}

sub _force {
	my $class = shift;
	if ( defined $ENV{PERL_RELEASE_TEST_FORCE} ) {
		return ( force => 1 );
	} else {
		return ();
	}
}



sub new_test_class_short {
	my $self          = shift;
	my $test_number   = shift;
	my $test_version  = shift;
	my $class_to_test = shift;
	my $testpath      = shift;

	if ( $OSNAME ne 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
	}
	if ( rel2abs( curdir() ) =~ m{[.]}ms ) {
		plan( skip_all =>
			  'Cannot be tested in a directory with an extension.' );
	}

	my $test_class =
	  $self->_create_test_class_short( $test_number, $test_version,
		$class_to_test );
	my $test_object = eval {
		my $obj =
		  $test_class->new( $self->_paths( $test_number, $testpath ),
			$self->_cpan_release(), $self->_forceperl(), $self->_force(),
			@_ );
		return $obj;
	};
	if ($EVAL_ERROR) {
		if ( blessed($EVAL_ERROR)
			&& $EVAL_ERROR->isa('Exception::Class::Base') )
		{
			diag( $EVAL_ERROR->as_string );
		} else {
			diag($EVAL_ERROR);
		}

		# Time to get out.
		BAIL_OUT('Error in test object creation.');
	} ## end if ($EVAL_ERROR)

	isa_ok( $test_object, $class_to_test );
	$tests_completed++;

	return $test_object;
} ## end sub new_test_class_short



sub new_test_class_medium {
	my $self          = shift;
	my $test_number   = shift;
	my $test_version  = shift;
	my $class_to_test = shift;
	my $testpath      = shift;

	if ( $OSNAME ne 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
	}
	if ( not -d 'blib') {
		plan( skip_all => 'Perl::Dist::WiX::Toolchain has problems if ' .  
		'dmake or Build has not been ran before testing.' );
	}
	if ( rel2abs( curdir() ) =~ m{[.]}ms ) {
		plan( skip_all =>
			  'Cannot be tested in a directory with an extension.' );
	}

	my $test_class =
	  $self->_create_test_class_medium( $test_number, $test_version,
		$class_to_test );
	my $test_object = eval {
		$test_class->new( $self->_paths( $test_number, $testpath ),
			$self->_cpan_release(), $self->_forceperl(), $self->_force(),
			@_ );
	};

	if ($EVAL_ERROR) {
		if ( blessed($EVAL_ERROR)
			&& $EVAL_ERROR->isa('Exception::Class::Base') )
		{
			diag( $EVAL_ERROR->as_string() );
		} else {
			diag($EVAL_ERROR);
		}

		# Time to get out.
		BAIL_OUT('Error in test object creation.');
	} ## end if ($EVAL_ERROR)

	isa_ok( $test_object, $class_to_test );
	$tests_completed++;

	return $test_object;
} ## end sub new_test_class_medium



sub new_test_class_long {
	my $self          = shift;
	my $test_number   = shift;
	my $test_version  = shift;
	my $class_to_test = shift;
	my $testpath      = shift;

	if ( $OSNAME ne 'MSWin32' ) {
		plan( skip_all => 'Not on Win32' );
	}
	if ( not -d 'blib') {
		plan( skip_all => 'Perl::Dist::WiX::Toolchain has problems if ' .  
		'dmake or Build has not been ran before testing.' );
	}
	if ( rel2abs( curdir() ) =~ m{[.]}ms ) {
		plan( skip_all =>
			  'Cannot be tested in a directory with an extension.' );
	}

	my $test_class =
	  $self->_create_test_class_long( $test_number, $test_version,
		$class_to_test );
	my $test_object = eval {
		$test_class->new( $self->_paths( $test_number, $testpath ),
			$self->_cpan_release(), $self->_forceperl(), $self->_force(),
			@_ );
	};

	if ($EVAL_ERROR) {
		if ( blessed($EVAL_ERROR)
			&& $EVAL_ERROR->isa('Exception::Class::Base') )
		{
			diag( $EVAL_ERROR->as_string );
		} else {
			diag($EVAL_ERROR);
		}

		# Time to get out.
		BAIL_OUT('Error in test object creation.');
	} ## end if ($EVAL_ERROR)

	isa_ok( $test_object, $class_to_test );
	$tests_completed++;

	return $test_object;
} ## end sub new_test_class_long



sub test_run_dist {
	my $dist = shift;

	# Run the dist object, and ensure everything we expect was created
	my $time  = scalar localtime;
	my $class = ref $dist;
	if ( $class !~ m/::Short/msx ) {
		diag("Building test dist @ $time.");
		if ( $class =~ m/::Long/msx ) {
			diag('Building may take several hours... (sorry)');
		} else {
			diag('Building may take an hour or two... (sorry)');
		}
	}
	ok( eval { $dist->run; 1; }, '->run ok' );
	if ($EVAL_ERROR) {
		if ( blessed($EVAL_ERROR)
			&& $EVAL_ERROR->isa('Exception::Class::Base') )
		{
			diag( $EVAL_ERROR->as_string );
		} else {
			diag($EVAL_ERROR);
		}
		BAIL_OUT('Could not run test object.');
	}
	$time = scalar localtime;
	if ( $class !~ m/::Short/msx ) {
		diag("Test dist finished @ $time.");
	}
	$tests_completed++;

	return;
} ## end sub test_run_dist



sub test_verify_files_short {
	my $test_number = shift;
	my $testpath = shift || 't';
	my $test_dir =
	  catdir( $testpath, "tmp$test_number", qw{ image c bin } );

	ok( -f catfile( $test_dir, qw{ dmake.exe } ), 'Found dmake.exe' );

	ok( -f catfile( $test_dir, qw{ startup Makefile.in } ),
		'Found startup' );

	$tests_completed += 2;

	return;
} ## end sub test_verify_files_short



sub test_verify_files_medium {
	my $test_number = shift;
	my $dll_version = shift;
	my $testpath    = shift || 't';

	my $dll_file = "perl${dll_version}.dll";
	my $test_dir = catdir( $testpath, "tmp$test_number", 'image' );

	# C toolchain files
	ok( -f catfile( $test_dir, qw{ c bin dmake.exe } ), 'Found dmake.exe',
	);
	ok( -f catfile( $test_dir, qw{ c bin startup Makefile.in } ),
		'Found startup',
	);
	ok( -f catfile( $test_dir, qw{ c bin pexports.exe } ),
		'Found pexports',
	);

	# Perl core files
	ok( -f catfile( $test_dir, qw{ perl bin perl.exe } ),
		'Found perl.exe',
	);

	if ( -f catfile( $test_dir, qw{ image portable.perl } ) ) {

		# Toolchain files
		ok( -f catfile( $test_dir, qw{ perl site lib LWP.pm } ),
			'Found LWP.pm', );

		# Custom installed file
		ok( -f catfile( $test_dir, qw{ perl site lib Config Tiny.pm } ),
			'Found Config::Tiny',
		);
	} else {

		# Toolchain files
		ok( -f catfile( $test_dir, qw{ perl vendor lib LWP.pm } ),
			'Found LWP.pm', );

		# Custom installed file
		ok( -f catfile( $test_dir, qw{ perl vendor lib Config Tiny.pm } ),
			'Found Config::Tiny',
		);
	}

	# Did we build Perl correctly?
	ok( -f catfile( $test_dir, qw{ perl bin }, $dll_file ),
		'Found Perl DLL',
	);

	$tests_completed += 7;

	return;
} ## end sub test_verify_files_medium



sub _create_test_class_short {
	my $self         = shift;
	my $test_number  = shift;
	my $test_version = shift;
	my $test_class   = shift;
	my $answer       = "Test::Perl::Dist::Short$test_number";

	my $code = <<"EOF";
		require $test_class;

		\@${answer}::ISA = ( "$test_class" );

		###############################################################
		# Configuration


		###############################################################
		# Main Methods

		sub ${answer}::new {
			return shift->${test_class}::new(
				perl_version  => $test_version,
				trace         => 1,
				build_number  => 1,
				app_publisher_url => 'http://vanillaperl.org',
				tasklist      => [qw(final_initialization install_dmake)],
				app_ver_name  => 'Test Perl 1 alpha 1',
				app_name      => 'Test Perl',
				app_publisher => 'Vanilla Perl Project',
				app_id        => 'testperl',
				\@_,
			);
		}
EOF

	eval $code;
	return $answer;
} ## end sub _create_test_class_short



sub _create_test_class_medium {
	my $self         = shift;
	my $test_number  = shift;
	my $test_version = shift;
	my $test_class   = shift;
	my $answer       = "Test::Perl::Dist::Medium$test_number";

	eval <<"EOF";
		require $test_class;

		\@${answer}::ISA = ( "$test_class" );

		###############################################################
		# Main Methods

		sub ${answer}::new {
			return shift->${test_class}::new(
				perl_version => $test_version,
				trace => 1,
				build_number => 1,
				app_publisher_url => 'http://vanillaperl.org',
				app_name      => 'Test Perl',
				app_ver_name  => 'Test Perl 1 alpha 1',
				app_publisher => 'Vanilla Perl Project',
				app_id        => 'testperl',
				tasklist      => [ qw(
					final_initialization
					install_c_toolchain
					install_perl
					install_perl_toolchain
					test_distro
					regenerate_fragments
					write
				)],
				\@_,
			);
		}

		sub ${answer}::test_distro {
			my \$self = shift;
			if (\$self->portable()) {
				\$self->install_distribution(
					name             => 'ADAMK/Config-Tiny-2.12.tar.gz',
					mod_name         => 'Config::Tiny',
					makefilepl_param => ['INSTALLDIRS=site'],
				);
			} else {
				\$self->install_distribution(
					name             => 'ADAMK/Config-Tiny-2.12.tar.gz',
					mod_name         => 'Config::Tiny',
					makefilepl_param => ['INSTALLDIRS=vendor'],
				);
			}
			return 1;
		}
EOF

	return $answer;
} ## end sub _create_test_class_medium



sub _create_test_class_long {
	my $self         = shift;
	my $test_number  = shift;
	my $test_version = shift;
	my $test_class   = shift;
	my $answer       = "Test::Perl::Dist::Long$test_number";

	eval <<"EOF";
		require $test_class;

		\@${answer}::ISA = ( "$test_class" );

		###############################################################
		# Main Methods

		sub ${answer}::new {
			return shift->${test_class}::new(
				perl_version => $test_version,
				trace => 1,
				build_number => 1,
				app_publisher_url => 'http://vanillaperl.org',
				app_name          => 'Test Perl',
				app_ver_name      => 'Test Perl 1 alpha 1',
				app_publisher     => 'Vanilla Perl Project',
				app_id            => 'testperl',
				\@_,
			);
		}
		
		sub ${answer}::install_cpan_upgrades {
			my \$self = shift;
			\$self->${test_class}::install_cpan_upgrades();
			if (\$self->portable()) {
				\$self->install_distribution(
					name             => 'ADAMK/Config-Tiny-2.12.tar.gz',
					mod_name         => 'Config::Tiny',
					makefilepl_param => ['INSTALLDIRS=site'],
				);
			} else {
				\$self->install_distribution(
					name             => 'ADAMK/Config-Tiny-2.12.tar.gz',
					mod_name         => 'Config::Tiny',
					makefilepl_param => ['INSTALLDIRS=vendor'],
				);
			}
			return 1;
		}
EOF

	return $answer;
} ## end sub _create_test_class_long



sub test_verify_files_long {
	my $test_number = shift;
	my $dll_version = shift;
	my $testpath    = shift || 't';

	my $dll_file = "perl${dll_version}.dll";
	my $test_dir = catdir( $testpath, "tmp$test_number", 'image' );

	# C toolchain files
	ok( -f catfile( $test_dir, qw{ c bin dmake.exe } ), 'Found dmake.exe',
	);

	ok( -f catfile( $test_dir, qw{ c bin startup startup.mk } ),
		'Found startup',
	);
	ok( -f catfile( $test_dir, qw{ c bin pexports.exe } ),
		'Found pexports',
	);

	# Perl core files
	ok( -f catfile( $test_dir, qw{ perl bin perl.exe } ),
		'Found perl.exe',
	);

	if ( -f catfile( $test_dir, qw{ image portable.perl } ) ) {

		# Toolchain files
		ok( -f catfile( $test_dir, qw{ perl site lib LWP.pm } ),
			'Found LWP.pm', );

		# Custom installed file
		ok( -f catfile( $test_dir, qw{ perl site lib Config Tiny.pm } ),
			'Found Config::Tiny',
		);
	} else {

		# Toolchain files
		ok( -f catfile( $test_dir, qw{ perl vendor lib LWP.pm } ),
			'Found LWP.pm', );

		# Custom installed file
		ok( -f catfile( $test_dir, qw{ perl vendor lib Config Tiny.pm } ),
			'Found Config::Tiny',
		);
	}

	# Did we build Perl correctly?
	ok( -f catfile( $test_dir, qw{ perl bin }, $dll_file ),
		'Found Perl DLL',
	);

	$tests_completed += 7;

	return;
} ## end sub test_verify_files_long



sub test_verify_portability {
	my $test_number   = shift;
	my $base_filename = shift;
	my $testpath      = shift || 't';

	my $test_dir = catdir( 't', "tmp$test_number" );

	# Did we build the zip file?
	ok( -f catfile( $test_dir, 'output', "${base_filename}.zip" ),
		'Found zip file',
	);

	# Did we build it portable?
	ok( -f catfile( $test_dir, qw{ image portable.perl } ),
		'Found portable file',
	);
	ok( -f catfile( $test_dir, qw{ image perl site lib Portable.pm } ),
		'Found Portable.pm',
	);

	$tests_completed += 3;

	return;
} ## end sub test_verify_portability



sub test_cleanup {
	my $test_number = shift;
	my $testpath = shift || 't';

	if ( Test::Builder->new()->is_passing() ) {

		diag('Removing build files on successful test.');
		my $dir = catdir( $testpath, "tmp$test_number" );
		File::Remove::remove( \1, $dir );
	} else {
		diag('Did not pass, so not removing files.');
	}

	return;
} ## end sub test_cleanup



sub done_testing {
	my $additional_tests = shift || 0;

	return Test::More::done_testing( $tests_completed + $additional_tests );
}

1;

__END__

=pod

=begin readme text

Test::Perl::Dist version 0.300

=end readme

=for readme stop

=head1 NAME

Test::Perl::Dist - Test module for Perl::Dist::WiX and subclasses.

=head1 VERSION

This document describes Test::Perl::Dist version 0.300

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

This method of installation requires that a current version of Module::Build 
be installed.
    
Alternatively, to install with Module::Build, you can use the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=end readme

=for readme stop

=head1 SYNOPSIS

	# This is the 901_perl_589.t file from Strawberry.
	#!/usr/bin/perl

	use strict;
	BEGIN {
		$|  = 1;
		$^W = 1;
	}

	use Test::Perl::Dist 0.300;
	use File::Spec::Functions qw(catdir);

	#####################################################################
	# Complete Generation Run

	# Create the dist object
	my $dist = Test::Perl::Dist->new_test_class_medium(
		901, '589', 'Perl::Dist::Strawberry', catdir(qw(xt release))
		msi => 0
	);

	test_run_dist( $dist );

	test_verify_files_medium(901, '58', catdir(qw(xt release));

	done_testing();

=head1 DESCRIPTION

This module implements a test framework for Perl::Dist::WiX and subclasses 
of that module.

Using Test::More is not required, as this module re-exports all its functions.

=head1 INTERFACE 

Note that this module exports all routines that are in 
L<Test::More|Test::More>, in addition to the routines documented here.

The only difference is in L<done_testing|/done_testing>, as documented below.

=head2 new_test_class_short

=head2 new_test_class_medium

=head2 new_test_class_long

	my $dist = Test::Perl::Dist->new_test_class_medium(
		901, '589', 'Perl::Dist::Strawberry', catdir(qw(xt release)),
		msi => 0
	);

Returns a distribution class to run and test against that is a subclass 
of the class being tested.

The first parameter is the test number, the second refers to the version of 
perl to build (589 for perl 5.8.9, for instance), the third is the class 
being tested, and the fourth is the directory the test is in.

Any parameters after that are passed to the constructor of the distribution 
class, which passes them on to the class being tested.

If the constructor of the class being tested returns an exception, that 
exception is printed, and all testing is stopped.

The difference between "short", "medium", and "long" is the expected length 
of the test. A "short" test installs the dmake binary and should not take 
more than 5 minutes, a "medium" test installs perl and one additional module 
and can take about an hour, and a "long" test completes a full build, which 
can take 4-8 hours on slow machines.

=head2 test_run_dist

	test_run_dist( $dist );

This runs the distribution class.

If the class being tested returns an exception when ran, that 
exception is printed, and all testing is stopped.

=head2 test_verify_files_short

=head2 test_verify_files_medium

=head2 test_verify_files_long

	test_verify_files_medium(901, '58', catdir(qw(xt release)));

This checks that certain files were created.

The first parameter is the test number, the second parameter refers to the 
first two parts of the perl version ('58' for 5.8.9, '510' for 5.10.0 or 
5.10.1), and the third parameter is the directory the test is in.

=head2 test_verify_portability

	test_verify_portability(901, $dist->output_base_filename(), catdir(qw(xt release)));

This checks that certain files were created that are required for a 
portable distribution.

The first parameter is the test number, the second parameter is the base 
filename of the dist being tested, as returned from output_base_filename, 
and the third parameter is the directory the test is in.

=head2 test_cleanup

	test_cleanup(901, catdir(xt release));
	
This cleans up the build files if all tests have been successful.

The first parameter is the test number, and the second parameter is the 
directory the test is in.

=head2 done_testing

	done_testing();
	
	# If additional tests were completed.
	done_testing(2);

This tells Test::Perl::Dist that all testing is completed.
	
If there is a parameter, it is the number of additional tests that were completed.

Test::Perl::Dist keeps track of the tests that it completed and adds it to this number.

=head1 DIAGNOSTICS

This module implements no diagnostics of its own, but reports diagnostics 
provided to it by the module being tested.

=head1 CONFIGURATION AND ENVIRONMENT

There are no configuration files.

$ENV{PERL_RELEASE_TEST_PERLDIST_CPAN} is used to point at a preferred 
(or local - it can be a file:// URL) mirror for CPAN.

If $ENV{PERL_RELEASE_TEST_FORCEPERL} is defined, it passes 
C<forceperl => 1> to the classes being tested, which skips testing perl
after compilation. This can speed up testing.

If $ENV{PERL_RELEASE_TEST_FORCE} is defined, it passes 
C<force => 1> to the classes being tested, which skips testing both
perl and the additional modules installed. This can speed up testing.

=for readme continue

=head1 DEPENDENCIES

This module requires perl 5.8.1, L<parent|parent> version 0.221,
L<File::Remove|File::Remove> version 1.42, L<LWP::Online|LWP::Online> version 
1.07, L<Test::More|Test::More> version 0.88, L<URI|URI> version 1.40, and
L<Win32|Win32> version 0.39.

=for readme stop

=head1 INCOMPATIBILITIES

0.300 has an incompatible API change to precious versions in order to support 
the tests not being in 't'.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Perl-Dist>
if you have an account there.

2) Email to E<lt>bug-Test-Perl-Dist@rt.cpan.orgE<gt> if you do not.

=head1 AUTHOR

Curtis Jewell  C<< <CSJewell@cpan.org> >>

=for readme continue

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009-2010, Curtis Jewell C<< <CSJewell@cpan.org> >>. 
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.8.1 or any later version. See L<perlartistic|perlartistic>
and L<perlgpl|perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=for readme stop

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
