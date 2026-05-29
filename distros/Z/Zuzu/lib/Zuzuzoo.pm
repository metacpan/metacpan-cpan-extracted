package Zuzuzoo;

use utf8;
use strict;
use warnings;

use Archive::Tar;
use File::Basename qw( basename dirname );
use File::Copy qw( copy );
use File::Find qw( find );
use File::Path qw( make_path );
use File::Spec;
use File::Temp qw( tempdir );
use Cwd qw( getcwd );
use JSON::PP;
use TAP::Parser;

use Zuzu::Parser;
use Zuzu::Runtime;

our $VERSION = '0.001000';

sub new {
	my ( $class, %args ) = @_;

	my $self = {
		lib_dir => $args{lib_dir},
		bin_dir => $args{bin_dir},
		meta_dir => $args{meta_dir},
		dry_run => $args{dry_run} ? 1 : 0,
	};

	return bless $self, $class;
}

sub install_tarball {
	my ( $self, $tarball, %args ) = @_;

	my $force = $args{force} ? 1 : 0;
	my $no_test = $args{no_test} ? 1 : 0;

	my $extract_dir = tempdir( CLEANUP => 1 );
	_extract_tarball( $tarball, $extract_dir );
	my $dist_root = _find_dist_root($extract_dir);
	_run_distribution_build( dist_root => $dist_root );

	my $metadata_path = File::Spec->catfile( $dist_root, 'zuzu-distribution.json' );
	die "Distribution is missing zuzu-distribution.json\n"
		if not -f $metadata_path;

	my $metadata = _read_json_file($metadata_path);
	my $name = _validate_text( $metadata, 'name' );
	my $version = _validate_text( $metadata, 'version' );
	_validate_text( $metadata, 'author' );
	_validate_text( $metadata, 'license' );

	my $modules = _discover_entries(
		dist_root => $dist_root,
		subdir => 'modules',
		kind => 'modules',
		ext => '.zzm',
	);
	my $scripts = _discover_entries(
		dist_root => $dist_root,
		subdir => 'scripts',
		kind => 'scripts',
		ext => '.zzs',
	);
	my $tests = _discover_test_paths( dist_root => $dist_root );
	my $dependencies = _normalize_dependencies( $metadata->{dependencies} );

	if ( not $no_test ) {
		my $test_result = _run_distribution_tests(
			dist_root => $dist_root,
			tests => $tests,
		);

		if ( not $test_result->{ok} ) {
			if ( $force ) {
				print "Test failures ignored due to --force\n";
			}
			else {
				die "Distribution tests failed; aborting install\n";
			}
		}
	}

	print "Installing $name v$version\n";
	$self->remove_prior_installations( $name, $version );

	for my $entry ( @{ $modules } ) {
		my $source = File::Spec->catfile( $dist_root, split m{/}, $entry->{source} );
		die "Module source '$entry->{source}' does not exist\n"
			if not -f $source;
		my $target = File::Spec->catfile( $self->{lib_dir}, split m{/}, $entry->{install_as} );
		print "  module $entry->{install_as}\n";
		_install_file( $source, $target, undef, $self->{dry_run} );
	}

	for my $entry ( @{ $scripts } ) {
		my $source = File::Spec->catfile( $dist_root, split m{/}, $entry->{source} );
		die "Script source '$entry->{source}' does not exist\n"
			if not -f $source;
		my $target = File::Spec->catfile( $self->{bin_dir}, split m{/}, $entry->{install_as} );
		my $mode = ( stat $source )[2] & 07777;
		print "  script $entry->{install_as}\n";
		_install_file( $source, $target, $mode, $self->{dry_run} );
	}

	my %meta_copy = %{ $metadata };
	$meta_copy{dependencies} = $dependencies;
	$meta_copy{installed} = {
		lib_dir => $self->{lib_dir},
		bin_dir => $self->{bin_dir},
		modules => $modules,
		scripts => $scripts,
		dependencies => $dependencies,
	};
	my $installed_meta = _metadata_file_for( $self->{meta_dir}, $name, $version );
	_write_json_file( $installed_meta, \%meta_copy, $self->{dry_run} );

	print $self->{dry_run} ? "Dry run complete\n" : "Install complete\n";
	return 0;
}

sub _run_distribution_build {
	my ( %args ) = @_;

	my $dist_root = $args{dist_root};
	my $build_script = File::Spec->catfile( $dist_root, 'Build.zzs' );
	return if not -f $build_script;

	my @build_cmd = _build_command_for_dist($dist_root);

	my $cwd = getcwd();
	chdir $dist_root
		or die "Could not enter distribution root '$dist_root': $!\n";
	my $exit = system( @build_cmd, 'Build.zzs' );
	my $code = $? >> 8;
	chdir $cwd
		or die "Could not return to '$cwd': $!\n";

	die "Build.zzs failed with exit code $code\n"
		if $exit != 0;

	return;
}

sub _build_command_for_dist {
	my ( $dist_root ) = @_;

	my @cmd;
	my @include_args = _build_include_args($dist_root);
	my $candidate = _zuzu_from_cli_name();
	if ( defined $candidate ) {
		@cmd = ( $^X, $candidate, @include_args );
		return @cmd;
	}

	@cmd = ( 'zuzu.pl', @include_args );
	return @cmd;
}

sub _zuzu_from_cli_name {
	my $candidate = $0;
	return undef
		if basename($candidate) ne 'zuzuzoo.pl';

	my $dir = dirname($candidate);
	my $zuzu = File::Spec->catfile( $dir, 'zuzu.pl' );
	return $zuzu
		if ( -f $zuzu and -x $zuzu );

	return undef;
}

sub _build_include_args {
	my ( $dist_root ) = @_;
	my @args;

	my $inc_dir = File::Spec->catdir( $dist_root, 'inc' );
	push @args, '-Iinc'
		if -d $inc_dir;
	push @args, '-Imodules'
		if -d File::Spec->catdir( $dist_root, 'modules' );

	return @args;
}

sub _discover_entries {
	my ( %args ) = @_;

	my $dist_root = $args{dist_root};
	my $subdir = $args{subdir};
	my $kind = $args{kind};
	my $ext = $args{ext};
	my $base_dir = File::Spec->catdir( $dist_root, $subdir );
	return []
		if not -d $base_dir;

	my @entries;
	find(
		{
			no_chdir => 1,
			wanted => sub {
				return if -d $_;
				return if $File::Find::name !~ /\Q$ext\E\z/;

				my $source = File::Spec->abs2rel( $File::Find::name, $dist_root );
				$source =~ s{\\}{/}g;
				my $install_as = File::Spec->abs2rel( $File::Find::name, $base_dir );
				$install_as =~ s{\\}{/}g;

				push @entries, {
					source => $source,
					install_as => $install_as,
				};
			},
		},
		$base_dir,
	);

	@entries = sort {
		$a->{source} cmp $b->{source}
	} @entries;

	return _normalize_entries( \@entries, $kind );
}

sub _discover_test_paths {
	my ( %args ) = @_;

	my $dist_root = $args{dist_root};
	my $tests_dir = File::Spec->catdir( $dist_root, 'tests' );
	return []
		if not -d $tests_dir;

	my @tests;
	find(
		{
			no_chdir => 1,
			wanted => sub {
				return if -d $_;
				return if $File::Find::name !~ /\.zzs\z/;
				my $path = File::Spec->abs2rel( $File::Find::name, $dist_root );
				$path =~ s{\\}{/}g;
				push @tests, $path;
			},
		},
		$tests_dir,
	);

	@tests = sort @tests;
	return \@tests;
}

sub _run_distribution_tests {
	my ( %args ) = @_;

	my $dist_root = $args{dist_root};
	my $tests = $args{tests} // [];
	return { ok => 1 } if not @{ $tests };

	my @scripts = @{ $tests };

	print "Running distribution tests\n";
	print "TAP version 13\n";
	print "1..", scalar(@scripts), "\n";

	my $cwd = getcwd();
	chdir $dist_root
		or die "Could not enter distribution root '$dist_root': $!\n";

	my $all_ok = 1;
	for my $i ( 0 .. $#scripts ) {
		my $display = $scripts[$i];
		my $script = File::Spec->catfile( $dist_root, split m{/}, $display );
		my $test_ok = _run_one_test_script(
			script => $script,
			display => $display,
			dist_root => $dist_root,
		);

		if ( $test_ok ) {
			print 'ok ', ( $i + 1 ), " - $display\n";
		}
		else {
			$all_ok = 0;
			print 'not ok ', ( $i + 1 ), " - $display\n";
		}
	}
	chdir $cwd
		or die "Could not return to '$cwd': $!\n";

	return { ok => $all_ok };
}

sub _run_one_test_script {
	my ( %args ) = @_;

	my $script = $args{script};
	my $display = $args{display};
	my $dist_root = $args{dist_root};

	my $source = _slurp_utf8($script);
	my $parser = Zuzu::Parser->new;
	my $ast = eval { $parser->parse( $source, $script ) };
	if ( not defined $ast ) {
		my $err = $@;
		$err =~ s/\s+\z//;
		print "# parse failed for $display\n";
		print "# $err\n" if defined $err and $err ne '';
		return 0;
	}

	my @lib = _runtime_lib_for_dist($dist_root);
	my $runtime = Zuzu::Runtime->new( lib => \@lib );

	my $tap_out = '';
	my $stderr_out = '';
	my $ran_ok = eval {
		local *STDOUT;
		local *STDERR;
		open STDOUT, '>:encoding(UTF-8)', \$tap_out
			or die "Could not capture test output for $display: $!";
		open STDERR, '>:encoding(UTF-8)', \$stderr_out
			or die "Could not capture test errors for $display: $!";
		$runtime->evaluate($ast);
		1;
	};

	if ( not $ran_ok ) {
		my $err = $@;
		$err =~ s/\s+\z//;
		print "# runtime failed for $display\n";
		print "# $err\n" if defined $err and $err ne '';
		if ( $stderr_out ne '' ) {
			for my $line ( split /\n/, $stderr_out ) {
				print "# stderr: $line\n";
			}
		}
		return 0;
	}

	if ( $stderr_out ne '' ) {
		for my $line ( split /\n/, $stderr_out ) {
			print "# stderr: $line\n";
		}
	}

	my $tap_parser = TAP::Parser->new( { source => \$tap_out } );
	my $tests_seen = 0;
	my $all_ok = 1;

	while ( my $result = $tap_parser->next ) {
		if ( $result->is_test ) {
			$tests_seen++;
			if ( not $result->is_ok ) {
				$all_ok = 0;
				my $desc = $result->description;
				$desc = 'unnamed test' if not defined $desc or $desc eq '';
				print "# failed TAP assertion: $desc\n";
			}
		}
		elsif ( $result->is_bailout ) {
			$all_ok = 0;
			print '# TAP bailout: ', $result->as_string, "\n";
		}
	}

	if ( not $tap_parser->is_good_plan ) {
		$all_ok = 0;
		print "# TAP plan is invalid for $display\n";
	}
	if ( $tap_parser->has_problems ) {
		$all_ok = 0;
		print "# TAP stream has parser problems for $display\n";
	}
	if ( $tests_seen == 0 ) {
		$all_ok = 0;
		print "# TAP stream has no tests for $display\n";
	}

	return $all_ok;
}

sub _runtime_lib_for_dist {
	my ( $dist_root ) = @_;

	my @lib;
	my $modules_dir = File::Spec->catdir( $dist_root, 'modules' );
	push @lib, $modules_dir
		if -d $modules_dir;

	my $inc_dir = File::Spec->catdir( $dist_root, 'inc' );
	push @lib, $inc_dir
		if -d $inc_dir;

	push @lib, $dist_root;
	push @lib, @Zuzu::Runtime::DEFAULT_LIB;

	return @lib;
}

sub _slurp_utf8 {
	my ( $path ) = @_;

	open my $fh, '<:encoding(UTF-8)', $path
		or die "Could not open '$path': $!\n";
	my $text = do {
		local $/;
		<$fh>;
	};
	close $fh;

	return $text;
}

sub remove_distribution {
	my ( $self, %args ) = @_;

	my $name = $args{name};
	my $version = $args{version};
	my @meta_files;

	if ( defined $version and $version ne '' ) {
		my $path = _metadata_file_for( $self->{meta_dir}, $name, $version );
		push @meta_files, $path if -f $path;
	}
	else {
		@meta_files = _meta_files_for_name( $self->{meta_dir}, $name );
	}

	die "No installed distribution metadata for '$name'\n"
		if not @meta_files;

	for my $meta_file ( @meta_files ) {
		print "Removing distribution via $meta_file\n";
		$self->remove_distribution_from_meta( meta_file => $meta_file );
	}

	return 0;
}

sub remove_prior_installations {
	my ( $self, $name, $version ) = @_;

	my @prior_meta = _meta_files_for_name( $self->{meta_dir}, $name );
	for my $prior_meta ( @prior_meta ) {
		my $keep = _metadata_file_for( $self->{meta_dir}, $name, $version );
		next if $prior_meta eq $keep;
		print "Removing prior installation from $prior_meta\n";
		$self->remove_distribution_from_meta( meta_file => $prior_meta );
	}

	return;
}

sub remove_distribution_from_meta {
	my ( $self, %args ) = @_;

	my $meta_file = $args{meta_file};
	my $meta = _read_json_file($meta_file);
	my $installed = $meta->{installed};
	my $modules = [];
	my $scripts = [];
	my $lib_dir = $self->{lib_dir};
	my $bin_dir = $self->{bin_dir};

	if ( ref($installed) eq 'HASH' ) {
		$modules = _normalize_entries( $installed->{modules}, 'modules' );
		$scripts = _normalize_entries( $installed->{scripts}, 'scripts' );
		$lib_dir = $installed->{lib_dir} if defined $installed->{lib_dir};
		$bin_dir = $installed->{bin_dir} if defined $installed->{bin_dir};
	}
	else {
		$modules = _normalize_entries( $meta->{modules}, 'modules' );
		$scripts = _normalize_entries( $meta->{scripts}, 'scripts' );
	}

	for my $entry ( @{ $modules } ) {
		my $path = File::Spec->catfile( $lib_dir, split m{/}, $entry->{install_as} );
		_remove_file( $path, $self->{dry_run} );
	}
	for my $entry ( @{ $scripts } ) {
		my $path = File::Spec->catfile( $bin_dir, split m{/}, $entry->{install_as} );
		_remove_file( $path, $self->{dry_run} );
	}

	if ( $self->{dry_run} ) {
		print "[dry-run] remove metadata $meta_file\n";
	}
	else {
		unlink $meta_file
			or die "Could not remove metadata '$meta_file': $!\n";
	}

	return;
}

sub _read_json_file {
	my ( $path ) = @_;

	open my $fh, '<:encoding(UTF-8)', $path
		or die "Could not open '$path': $!\n";
	my $json_text = do {
		local $/;
		<$fh>;
	};
	close $fh;

	my $decoded = eval { JSON::PP->new->utf8->decode($json_text) };
	die "Could not parse JSON from '$path': $@\n" if $@;
	die "JSON in '$path' must be an object\n"
		if ref($decoded) ne 'HASH';

	return $decoded;
}

sub _write_json_file {
	my ( $path, $data, $dry_run ) = @_;

	if ( $dry_run ) {
		print "[dry-run] write metadata $path\n";
		return;
	}

	my $dir = dirname($path);
	make_path($dir) if not -d $dir;

	open my $fh, '>:encoding(UTF-8)', $path
		or die "Could not write '$path': $!\n";
	print {$fh} JSON::PP->new->utf8->canonical->pretty->encode($data);
	close $fh;

	return;
}

sub _validate_text {
	my ( $metadata, $key ) = @_;

	my $value = $metadata->{$key};
	die "Metadata field '$key' is required\n"
		if not defined $value;
	my $as_text = "$value";
	die "Metadata field '$key' must not be empty\n"
		if $as_text eq '';

	return $as_text;
}

sub _normalize_entries {
	my ( $entries, $kind ) = @_;

	$entries = [] if not defined $entries;
	die "Metadata field '$kind' must be an array\n"
		if ref($entries) ne 'ARRAY';

	my @out;
	for my $entry ( @{ $entries } ) {
		if ( ref($entry) eq '' ) {
			my $source = "$entry";
			die "Empty '$kind' source entry\n" if $source eq '';
			my $install_as = $kind eq 'modules'
				? $source
				: basename($source);
			push @out, {
				source => $source,
				install_as => $install_as,
			};
			next;
		}

		die "Entries in '$kind' must be strings or objects\n"
			if ref($entry) ne 'HASH';
		my $source = $entry->{source};
		die "'$kind' object entry requires 'source'\n"
			if not defined $source or "$source" eq '';
		my $install_as = $entry->{install_as};
		if ( not defined $install_as or "$install_as" eq '' ) {
			$install_as = $kind eq 'modules'
				? "$source"
				: basename("$source");
		}
		push @out, {
			source => "$source",
			install_as => "$install_as",
		};
	}

	return \@out;
}

sub _normalize_dependencies {
	my ( $dependencies ) = @_;

	$dependencies = {} if not defined $dependencies;
	die "Metadata field 'dependencies' must be an object\n"
		if ref($dependencies) ne 'HASH';

	my %out;
	for my $module_name ( keys %{ $dependencies } ) {
		die "Dependency module names must not be empty\n"
			if $module_name eq '';

		my $min_version = $dependencies->{$module_name};
		die "Dependency '$module_name' requires a minimum version\n"
			if not defined $min_version;
		my $as_text = "$min_version";
		die "Dependency '$module_name' minimum version must not be empty\n"
			if $as_text eq '';

		$out{$module_name} = $as_text;
	}

	return \%out;
}

sub _install_file {
	my ( $source, $target, $mode, $dry_run ) = @_;

	my $target_dir = dirname($target);
	if ( $dry_run ) {
		print "[dry-run] mkdir -p $target_dir\n";
		print "[dry-run] copy $source -> $target\n";
		return;
	}

	make_path($target_dir) if not -d $target_dir;
	copy( $source, $target )
		or die "Could not copy '$source' to '$target': $!\n";
	if ( defined $mode ) {
		chmod $mode, $target
			or die "Could not chmod '$target': $!\n";
	}

	return;
}

sub _remove_file {
	my ( $path, $dry_run ) = @_;

	return if not -e $path;
	if ( $dry_run ) {
		print "[dry-run] remove $path\n";
		return;
	}

	unlink $path
		or die "Could not remove '$path': $!\n";

	return;
}

sub _extract_tarball {
	my ( $tarball, $extract_dir ) = @_;

	die "Tarball '$tarball' does not exist\n"
		if not -e $tarball;
	die "Tarball '$tarball' is not a file\n"
		if not -f $tarball;

	my $cwd = File::Spec->rel2abs( File::Spec->curdir() );
	my $tar = Archive::Tar->new;
	$tar->read($tarball)
		or die "Could not read tarball '$tarball'\n";

	chdir $extract_dir
		or die "Could not enter temp dir '$extract_dir': $!\n";
	$tar->extract()
		or die "Could not extract tarball '$tarball'\n";
	chdir $cwd
		or die "Could not return to '$cwd': $!\n";

	return;
}

sub _find_dist_root {
	my ( $extract_dir ) = @_;

	opendir my $dh, $extract_dir
		or die "Could not open '$extract_dir': $!\n";
	my @entries = grep { $_ ne '.' and $_ ne '..' }
		readdir $dh;
	closedir $dh;

	if ( @entries == 1 ) {
		my $candidate = File::Spec->catfile( $extract_dir, $entries[0] );
		return $candidate if -d $candidate;
	}

	return $extract_dir;
}

sub _metadata_file_for {
	my ( $meta_dir, $name, $version ) = @_;

	return File::Spec->catfile( $meta_dir, "$name-$version.json" );
}

sub _meta_files_for_name {
	my ( $meta_dir, $name ) = @_;

	return () if not -d $meta_dir;
	opendir my $dh, $meta_dir
		or die "Could not open '$meta_dir': $!\n";
	my @files;
	while ( my $entry = readdir $dh ) {
		next if $entry eq '.' or $entry eq '..';
		next if $entry !~ /^\Q$name\E-(.+)\.json\z/;
		push @files, File::Spec->catfile( $meta_dir, $entry );
	}
	closedir $dh;

	return sort @files;
}

=pod

=head1 NAME

Zuzuzoo - install and remove Zuzu module distributions

=head1 SYNOPSIS

  use Zuzuzoo;

  my $zoo = Zuzuzoo->new(
    lib_dir  => '/home/alex/.zuzu/modules',
    bin_dir  => '/home/alex/.zuzu/bin',
    meta_dir => '/home/alex/.zuzu/meta',
    dry_run  => 0,
  );

  $zoo->install_tarball( '/tmp/my-dist.tar.gz' );
  $zoo->remove_distribution( name => 'my-dist' );

=head1 DESCRIPTION

C<Zuzuzoo> is the programmatic API behind the C<zuzuzoo>
installer command. It can install a distribution tarball,
remove an installed distribution, and remove old installed
versions based on metadata records.

=head1 METHODS

=head2 new

Create a new installer instance.

Required keys:

=over 4

=item * C<lib_dir>

Directory where module files are copied.

=item * C<bin_dir>

Directory where script files are copied.

=item * C<meta_dir>

Directory used for install metadata JSON files.

=back

Optional keys:

=over 4

=item * C<dry_run>

When true, actions are printed without changing files.

=back

=head2 install_tarball

Install a distribution from a tarball path. Returns C<0>
on success and dies on fatal errors.

=head2 remove_distribution

Remove an installed distribution by C<name>, optionally
limited by C<version>. Returns C<0> on success and dies on
fatal errors.

=head2 remove_prior_installations

Remove all installed metadata records for C<name> except the
provided C<version>.

=head2 remove_distribution_from_meta

Remove files listed in one metadata record and delete the
metadata JSON file.

=head1 COPYRIGHT AND LICENCE

B<< Zuzuzoo >> is copyright Toby Inkster.

It is free software; you may redistribute it and/or modify it under
the terms of either the Artistic License 1.0 or the GNU General Public
License version 2.

=cut

1;
