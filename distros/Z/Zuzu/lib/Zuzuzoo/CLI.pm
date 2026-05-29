package Zuzuzoo::CLI;

use utf8;
use strict;
use warnings;

our $VERSION = '0.001000';

use File::Spec;
use Getopt::Long qw(
	Configure
	GetOptionsFromArray
);

use Zuzuzoo;

sub run {
	my ( @argv ) = @_;
	@argv = @ARGV if not @argv;

	my ( $options, $args, $error ) = _parse_options( \@argv );
	if ( defined $error ) {
		_print_usage($error);
		return 2;
	}

	my ( $paths, $path_error ) = _resolve_paths($options);
	if ( defined $path_error ) {
		_print_usage($path_error);
		return 2;
	}

	my $zoo = Zuzuzoo->new(
		lib_dir => $paths->{lib_dir},
		bin_dir => $paths->{bin_dir},
		meta_dir => $paths->{meta_dir},
		dry_run => $options->{dry_run},
	);

	if ( defined $options->{remove_name} ) {
		return _run_remove( $zoo, $options, $args );
	}

	my ( $tarball, $arg_error ) = _extract_tarball_arg($args);
	if ( defined $arg_error ) {
		_print_usage($arg_error);
		return 2;
	}

	$zoo->install_tarball(
		$tarball,
		force => $options->{force},
		no_test => $options->{no_test},
	);
	return 0;
}

sub _parse_options {
	my ( $argv ) = @_;

	my $options = {
		global => 0,
		dry_run => 0,
		help => 0,
		force => 0,
		no_test => 0,
	};

	Configure(
		'no_ignore_case',
		'bundling',
	);

	my $ok = GetOptionsFromArray(
		$argv,
		'global|g' => \$options->{global},
		'dry-run|n' => \$options->{dry_run},
		'help|h' => \$options->{help},
		'lib-dir=s' => \$options->{lib_dir},
		'bin-dir=s' => \$options->{bin_dir},
		'meta-dir=s' => \$options->{meta_dir},
		'remove=s' => \$options->{remove_name},
		'version=s' => \$options->{remove_version},
		'force' => \$options->{force},
		'no-test' => \$options->{no_test},
	);
	return ( undef, undef, undef ) if not $ok;

	if ( $options->{help} ) {
		return ( undef, undef, '' );
	}

	return ( $options, $argv, undef );
}

sub _resolve_paths {
	my ( $options ) = @_;

	my $home = $ENV{HOME};
	if (
		( not $options->{global} )
		and $^O ne 'MSWin32'
		and ( not defined $home or $home eq '' )
	) {
		return ( undef, 'HOME must be defined unless --global is used' );
	}
	if (
		( not $options->{global} )
		and $^O eq 'MSWin32'
		and ( not defined $ENV{LOCALAPPDATA} or $ENV{LOCALAPPDATA} eq '' )
		and ( not defined $home or $home eq '' )
	) {
		return ( undef, 'LOCALAPPDATA or HOME must be defined unless --global is used' );
	}

	my $lib_dir = defined $options->{lib_dir}
		? $options->{lib_dir}
		: $options->{global}
			? _global_modules_dir()
			: _user_modules_dir($home);

	my $bin_dir = defined $options->{bin_dir}
		? $options->{bin_dir}
		: $options->{global}
			? '/usr/local/bin'
			: File::Spec->catdir( $home, '.zuzu', 'bin' );

	my $meta_dir = defined $options->{meta_dir}
		? $options->{meta_dir}
		: $options->{global}
			? '/var/lib/zuzu/meta'
			: File::Spec->catdir( $home, '.zuzu', 'meta' );

	return ({
		lib_dir => $lib_dir,
		bin_dir => $bin_dir,
		meta_dir => $meta_dir,
	}, undef);
}

sub _user_modules_dir {
	my ( $home ) = @_;
	return File::Spec->catdir( $ENV{LOCALAPPDATA}, 'Zuzu', 'modules' )
		if $^O eq 'MSWin32' and defined $ENV{LOCALAPPDATA} and $ENV{LOCALAPPDATA} ne '';
	return File::Spec->catdir( $home, '.zuzu', 'modules' );
}

sub _global_modules_dir {
	return File::Spec->catdir( $ENV{ProgramData}, 'Zuzu', 'modules' )
		if $^O eq 'MSWin32' and defined $ENV{ProgramData} and $ENV{ProgramData} ne '';
	return '/var/lib/zuzu/modules';
}

sub _run_remove {
	my ( $zoo, $options, $args ) = @_;

	if ( @{ $args } ) {
		_print_usage('Tarball path is not allowed with --remove');
		return 2;
	}

	$zoo->remove_distribution(
		name => $options->{remove_name},
		version => $options->{remove_version},
	);
	return 0;
}

sub _extract_tarball_arg {
	my ( $args ) = @_;

	my $tarball = shift @{ $args };
	return ( undef, '' ) if not defined $tarball;
	return ( undef, 'Too many arguments' ) if @{ $args };

	return ( $tarball, undef );
}

sub _print_usage {
	my ( $message ) = @_;

	if ( defined $message and $message ne '' ) {
		print STDERR $message, "\n";
	}

	print STDERR "Usage:\n";
	print STDERR "  zuzuzoo [options] path/to/distribution.tar[.gz]\n";
	print STDERR "  zuzuzoo [options] --remove NAME [--version VERSION]\n";
	print STDERR "\nOptions:\n";
	print STDERR "  --global            install into system locations\n";
	print STDERR "  --lib-dir=DIR       override module install directory\n";
	print STDERR "  --bin-dir=DIR       override script install directory\n";
	print STDERR "  --meta-dir=DIR      override metadata install directory\n";
	print STDERR "  --remove=NAME       uninstall an installed distribution\n";
	print STDERR "  --version=VERSION   with --remove, limit to a version\n";
	print STDERR "  --force             install even when tests fail\n";
	print STDERR "  --no-test           skip distribution test execution\n";
	print STDERR "  --dry-run           print actions but do not modify files\n";
	print STDERR "  --help              show this help\n";

	return;
}

1;

=pod

=head1 COPYRIGHT AND LICENCE

B<< Zuzuzoo::CLI >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut
