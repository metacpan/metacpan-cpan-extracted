package Module::Build::Scintilla;

use 5.006;
use strict;
use warnings;
use Module::Build;
use Config;

our @ISA = qw( Module::Build );

sub stc_builderclass {

	# get builder class
	# based on OS && Config as we can't
	# load alien and we are never likely
	# to support a *nix toolkit other than
	# gtk

	my $bclass;

	if ( $^O =~ /^mswin/i ) {
		if ( $Config{cc} eq 'cl' ) {
			require Module::Build::Scintilla::MSW;
			$bclass = 'Module::Build::Scintilla::MSW';
		} else {
			require Module::Build::Scintilla::MSWgcc;
			$bclass = 'Module::Build::Scintilla::MSWgcc';
		}
	} elsif ( $^O =~ /^darwin/i ) {
		require Module::Build::Scintilla::OSX;
		$bclass = 'Module::Build::Scintilla::OSX';
	} else {
		require Module::Build::Scintilla::GTK;
		$bclass = 'Module::Build::Scintilla::GTK';
	}

	return $bclass;
}

sub stc_extra_scintilla_libs { ''; }

sub stc_prebuild_check { 1; }

sub stc_wxconfig {
	my $self = shift;

	# not available on windows
	return $self->{_wxstc_config_wxconfig} if $self->{_wxstc_config_wxconfig};
	my $binpathconfig;
	my $sympathconfig = Alien::wxWidgets->prefix . '/bin/wx-config';

	# sometimes the symlink is broken - if there has been relocation etc.
	# but we know where it should be if installed by Alien::wxWidgets
	# For system installs, 'wx-config' should work

	eval {
		my $location = readlink($sympathconfig);
		my @sympaths = split( /\//, $location );
		my $testpath = Alien::wxWidgets->prefix . '/lib/wx/config/' . $sympaths[-1];
		$binpathconfig = $testpath if -f $testpath;
	};

	my $wxconfig = $binpathconfig || 'wx-config';
	my $configtest = qx($wxconfig --version);
	if ( $configtest !~ /^\d+\.\d+\.\d+/ ) {
		die
			'Cannot find wx-config for wxWidgets. Perhaps you need to install wxWidgets development libraries for your system?';
	}
	$self->{_wxstc_config_wxconfig} = $wxconfig;
	return $self->{_wxstc_config_wxconfig};
}

sub stc_version_strings {
	my $class   = shift;
	my $version = Alien::wxWidgets->version;
	my $major   = substr( $version, 0, 1 );
	my $minor   = 1 * substr( $version, 2, 3 );
	my $release = 1 * substr( $version, 5, 3 );
	return ( $major, $minor, $release );
}

sub stc_linker {
	my $self    = shift;
	my $command = $self->stc_wxconfig . ' --ld';
	my $linker  = qx($command);
	chomp($linker);
	return $linker;
}

sub stc_ldflags {
	my $self = shift;
	return Alien::wxWidgets->link_flags;
}

sub stc_defines {
	my $self = shift;
	my $defines =
		Alien::wxWidgets->defines . ' -DWXBUILDING -DSCI_LEXER -DLINK_LEXERS -DWXUSINGDLL -DWXMAKINGDLL_STC -D__WX__';
	return $defines;
}

sub stc_compiler {
	my $self     = shift;
	my $command  = $self->stc_wxconfig . ' --cc';
	my $compiler = qx($command);
	chomp($compiler);
	{
		my @commands = split( /\s/, $compiler );
		$commands[0] =~ s/^gcc/g\+\+/;
		$commands[0] .= ' -c';
		$compiler = join( ' ', @commands );
	}
	return $compiler;
}

sub stc_ccflags {
	my $self    = shift;
	my $command = $self->stc_wxconfig . ' --cxxflags';
	my $flags   = qx($command);
	chomp($flags);
	$flags .= ' ' . Alien::wxWidgets->c_flags;
	return $flags;
}

sub ACTION_build {
	my $self = shift;

	require Alien::wxWidgets;
	Alien::wxWidgets->import;

	# check wx widgets version
	my $wxversion = Alien::wxWidgets->version;
	
	#if ( $wxversion !~ /^2\.008/ ) {
	#	die("Wx::Scintilla does not support wxWidgets version $wxversion");
	#}

	$self->stc_prebuild_check;

	$self->build_scintilla();
	$self->build_xs();
	$self->SUPER::ACTION_build;
}

# Build test action invokes build first
sub ACTION_test {
	my $self = shift;

	$self->depends_on('build');
	$self->SUPER::ACTION_test;
}

# Build install action invokes build first
sub ACTION_install {
	my $self = shift;

	$self->depends_on('build');
	$self->SUPER::ACTION_install;
}

sub process_xs_files {
	my $self = shift;

	# Override Module::Build with a null implementation
	# We will be doing our own custom XS file handling
}

#
# Joins the list of commands to form a command, executes it a C<system> call
# and handles CTRL-C and bad exit codes
#

sub _run_command {
	my $self = shift;
	my $cmds = shift;

	my $cmd = join( ' ', @$cmds );
	if ( !$self->verbose and $cmd =~ /(cc|gcc|g\+\+|cl).+-o\s+(\S+)/ ) {
		my $object_name = File::Basename::basename($2);
		$self->log_info("    CC -o $object_name\n");
	} else {
		$self->log_info("$cmd\n");
	}
	my $rc = system($cmd);
	die "Failed with exit code $rc\n$cmd\n"  if $rc != 0;
	die "Ctrl-C interrupted command\n$cmd\n" if $rc & 127;
}

sub build_scintilla {
	my $self = shift;

	my @modules = (
		glob('wx-scintilla/src/scintilla/src/*.cxx'),
		'wx-scintilla/src/PlatWX.cpp',
		'wx-scintilla/src/ScintillaWX.cpp',
		'wx-scintilla/src/scintilla.cpp',
	);

	my @include_dirs = (
		'-Iwx-scintilla/include',
		'-Iwx-scintilla/src/scintilla/include',
		'-Iwx-scintilla/src/scintilla/src',
		'-Iwx-scintilla/src',
		Alien::wxWidgets->include_path,
	);

	# Trigger a smart object build if one of the source files is not up to date
	my @objects = ();
	for my $module (@modules) {
		my $filename = File::Basename::basename($module);
		my $objext   = $Config{obj_ext};
		$filename =~ s/\.(c|cpp|cxx)$/$objext/;
		my $object_name = File::Spec->catfile( File::Basename::dirname($module), "scintilladll_$filename" );
		unless ( $self->up_to_date( $module, $object_name ) ) {
			$self->stc_build_scintilla_object( $module, $object_name, \@include_dirs );
		}
		push @objects, $object_name;
	}

	# Create distribution share directory
	my $dist_dir = 'blib/arch/auto/Wx/Scintilla';
	File::Path::mkpath( $dist_dir, 0, oct(777) );

	my $shared_lib = File::Spec->catfile( $dist_dir, $self->stc_scintilla_dll );

	# Trigger a smart shared library build if one of the object files is not up to date
	for my $object (@objects) {
		unless ( $self->up_to_date( $object, $shared_lib ) ) {
			$self->stc_link_scintilla_objects( $shared_lib, \@objects );
			last;
		}
	}
}

sub build_xs {
	my $self = shift;

	my $perltypemap;

	for (@INC) {
		my $checkfile = qq($_/ExtUtils/typemap);
		if ( -f $checkfile ) {
			$perltypemap = $checkfile;
			$perltypemap =~ s/\\/\//g;
			last;
		}
	}

	die 'Unable to determine typemap' if !defined($perltypemap);

	# Trigger a smart XS build only if it is not up to date.
	my ( $scintilla_xs, $scintilla_c ) = ( 'Scintilla.xs', 'Scintilla.c' );
	unless ( $self->up_to_date( $scintilla_xs, $scintilla_c ) ) {
		$self->log_info("    $scintilla_xs -> $scintilla_c\n");
		require ExtUtils::ParseXS;
		ExtUtils::ParseXS::process_file(
			filename    => $scintilla_xs,
			output      => $scintilla_c,
			prototypes  => 0,
			linenumbers => 0,
			typemap     => [
				File::Spec->catfile($perltypemap),
				'wx_typemap',
				'typemap',
			],
		);
	}

	if ( open my $fh, '>Scintilla.bs' ) {
		close $fh;
	}

	$self->stc_build_xs;

	my $dll = File::Spec->catfile( 'blib/arch/auto/Wx/Scintilla', 'Scintilla.' . $Config{dlext} );

	# Trigger a smart XS link only if it is not up to date.
	$self->stc_link_xs($dll) unless $self->up_to_date( $scintilla_c, $dll );

	chmod( 0755, $dll );

	require File::Copy;
	unlink('blib/arch/auto/Wx/Scintilla/Scintilla.bs');
	File::Copy::copy( 'Scintilla.bs', 'blib/arch/auto/Wx/Scintilla/Scintilla.bs' ) or die "Cannot copy Scintilla.bs\n";
	chmod( 0644, 'blib/arch/auto/Wx/Scintilla/Scintilla.bs' );
}

sub stc_get_wx_include_path {
	my $self = shift;
	eval { require Wx::Mini; };
	my $minipath = $INC{'Wx/Mini.pm'};
	return '' if !$minipath;
	my ( $vol, $dir, $file ) = File::Spec->splitpath($minipath);
	my @dirs = File::Spec->splitdir($dir);
	return File::Spec->catpath( $vol, File::Spec->catdir(@dirs), '' );
}

1;
