package Module::Build::Scintilla::OSX;

use 5.006;
use strict;
use warnings;
use Module::Build::Scintilla;
use Config;

our @ISA = qw( Module::Build::Scintilla );

sub ACTION_install {
	my $self   = shift;
	my $result = $self->SUPER::ACTION_install(@_);
	$self->stc_install_scintilla_library;
	$self->stc_install_scintilla_bundle;
	return $result;
}

sub stc_linker {
	my $self    = shift;
	my $command = $self->stc_wxconfig . ' --ld';
	my $linker  = qx($command);
	chomp($linker);

	# strip -o for macosx
	$linker =~ s/ -o\s*$//;
	return $linker;
}

sub stc_scintilla_lib {''}

sub stc_scintilla_dll {
	my $self    = shift;
	my $dllname = 'libwx_mac';
	$dllname .= 'u' if Alien::wxWidgets->config->{unicode};
	$dllname .= 'd' if Alien::wxWidgets->config->{debug};
	$dllname .= '_scintilla-';
	my ( $major, $minor, $release ) = $self->stc_version_strings;
	$dllname .= $major . '.' . $minor . '.' . $release . '.dylib';
	return $dllname;
}

sub stc_framework_prefix {
	my $self   = shift;
	my $prefix = 'libwx_mac';
	$prefix .= 'u' if Alien::wxWidgets->config->{unicode};
	$prefix .= 'd' if Alien::wxWidgets->config->{debug};
	$prefix .= '_scintilla';
	return $prefix;
}

sub stc_scintilla_link { $_[0]->stc_scintilla_dll; }

sub stc_build_scintilla_object {
	my ( $self, $module, $object_name, $includedirs ) = @_;

	my @cmd = (
		$self->stc_compiler,
		$self->stc_get_architecture_string,
		$self->stc_ccflags,
		$self->stc_defines,
		'-o ' . $object_name,
		'-O2',
		'-Wall',
		$object_name !~ /((Plat|Scintilla)WX|scintilla)\.o/
		? '-Wno-missing-braces -Wno-char-subscripts'
		: '',
		join( ' ', @$includedirs ),
		$module,
	);

	$self->_run_command( \@cmd );
}

sub stc_link_scintilla_objects {
	my ( $self, $shared_lib, $objects ) = @_;

    # fix missing symbols when compiled against cocoa
    my $baseflags = '-headerpad_max_install_names -shared';
    if( Alien::wxWidgets->version >= 2.009 ) {
        $baseflags .= ' -framework CoreFoundation';
    }
    
	my @cmd = (
		$self->stc_linker,
		$self->stc_get_architecture_string,
		$self->stc_ldflags,
		$baseflags,
		' -o ' . $shared_lib,
		join( ' ', @$objects ),
		Alien::wxWidgets->libraries(qw(core base)),
	);

	$self->_run_command( \@cmd );
}

sub stc_build_xs {
	my ($self) = @_;

	# Do not build XS if it is up to date
	return if $self->up_to_date( 'Scintilla.c', 'Scintilla.o' );

	my $dist_version = $self->dist_version;

	# we must remove any nostdinc params
	my $ccflags = $Config{ccflags};
	$ccflags =~ s/-nostdinc //g;

	my @cmd = (
		Alien::wxWidgets->compiler,
		$self->stc_get_architecture_string,
		' -c',
		'-I.',
		'-I' . $self->stc_get_wx_include_path,
		'-I' . $Config{archlibexp} . '/CORE',
		Alien::wxWidgets->include_path,
		Alien::wxWidgets->c_flags,
		Alien::wxWidgets->defines,
		$ccflags,
		$Config{optimize},
		'-DWXPL_EXT -DVERSION=\"' . $dist_version . '\" -DXS_VERSION=\"' . $dist_version . '\"',
		'Scintilla.c',
	);

	$self->_run_command( \@cmd );
}


sub stc_link_xs {
	my ( $self, $dll ) = @_;

	# we must remove any nostdinc params
	my $ldflags = $Config{lddlflags};
	$ldflags =~ s/-nostdinc //g;

	my @cmd = (
		Alien::wxWidgets->linker,
		$self->stc_get_architecture_string,
		Alien::wxWidgets->link_flags,
		'-headerpad_max_install_names',
		$ldflags,
		'-L.',
		'-s -o ' . $dll,
		'Scintilla.o',
		'blib/arch/auto/Wx/Scintilla/' . $self->stc_scintilla_link,
		Alien::wxWidgets->libraries(qw(core base)),
		$Config{perllibs},
	);

	$self->_run_command( \@cmd );

}

# We need our own run command to strip out none buildable architectures
sub _run_command {
	my $self = shift;
	my $cmds = shift;
	my $cmd  = join( ' ', @$cmds );

	my $archconf = $self->stc_get_architectures;

	foreach my $arch ( sort keys(%$archconf) ) {
		if ( !$archconf->{$arch} ) {
			$cmd =~ s/-arch $arch //g;
		}
	}
	
	# fix for Lion users who built wxWidgets with Xcode 4.1
	# but later upgraded to Xcode 4.3 +
	{
		my $xcodeold = '/Developer/SDKs/MacOSX10.6.sdk';
		my $xcodenew = '/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.6.sdk';
		
		if( -d $xcodenew  && $cmd !~ /\Q$xcodenew\E/ ) {
		    $cmd =~ s/\Q$xcodeold\E/$xcodenew/g;
		}
	}
	

	$self->log_info("$cmd\n");
	my $rc = system($cmd);
	die "Failed with exit code $rc" if $rc != 0;
	die "Ctrl-C interrupted command\n" if $rc & 127;
}

sub stc_get_architectures {
	my $self = shift;

	my $archtext = '';
	my $ldflags  = $Config{ldflags};

	my %allowed;

	if ( Alien::wxWidgets->version >= 2.009 ) {
		%allowed = ( i386 => 1, ppc => 1, 'x86_64' => 1, ppc64 => 0 );

		# can't test ppc64 and probably can't build it
	} else {
		%allowed = ( i386 => 1, ppc => 1, 'x86_64' => 0, ppc64 => 0 );
	}

	my %config;

	foreach my $arch ( sort keys(%allowed) ) {
		if ( $ldflags =~ /-arch $arch/i ) {
			$config{$arch} = $allowed{$arch};
		} else {
			$config{$arch} = 0;
		}
	}
	
	# if this is 2.009 and we have x86_64, delete i386 as we can't build it
	# at the same time
	if ( (Alien::wxWidgets->version >= 2.009 ) && ( $config{'x86_64'} == 1 ) ) {
		$config{'i386'} = 0;
    }
	
	return \%config;
}

sub stc_get_architecture_string {
	my $self       = shift;
	my $config     = $self->stc_get_architectures;
	my $archstring = '';
	foreach my $arch ( sort keys(%$config) ) {
		$archstring .= qq(-arch $arch ) if $config->{$arch};
	}
	return $archstring;
}

sub stc_install_scintilla_library {
	my ($self) = @_;

	# Set Params
	my $fworkprefix = $self->stc_framework_prefix;
	my $libname     = $self->stc_scintilla_dll;
	my $targetfile  = File::Spec->catfile( $self->install_destination('arch'), 'auto/Wx/Scintilla/' . $libname );
	my $newprefix   = File::Spec->catfile( $self->install_destination('arch'), 'auto/Wx/Scintilla' );

	my $storedmode = ( stat($targetfile) )[2];
	my $newmode    = $storedmode | 0220;
	chmod( $newmode, $targetfile );

	my $libfixedpart;
	if ( $libname =~ /^([^\d\.]+)([\d\.]+)dylib$/ ) {
		$libfixedpart = $1;
	} else {
		warn("Could not parse libary name for $libname. Shared library may fail in distribution");
		chmod( $storedmode, $targetfile );
		return;
	}

	#---------------------------------------------------
	# UPDATE THE LIBRARY ID
	# --------------------------------------------------
	my $idcommand = 'otool -DX "' . $targetfile . '"| grep -e ' . qq('$fworkprefix') . ' | cut -d " " -f 1';

	my @outputlines = qx($idcommand);
	unless ( scalar @outputlines ) {
		warn("Could not parse libary ID for $libname. Shared library may fail in distribution");
		chmod( $storedmode, $targetfile );
		return;
	}

	my $truelibraryname;
	my $oldlibraryname;
	my %seenlines = ();
	for my $oline (@outputlines) {
		chomp($oline);
		next if ( exists( $seenlines{$oline} ) );
		$seenlines{$oline} = 1;
		if ( $oline =~ /^(.+)\Q$libfixedpart\E([\d\.]+dylib)$/ ) {
			$truelibraryname = $libfixedpart . $2;
			$oldlibraryname  = $oline;
			last;
		}
	}
	if ( !$truelibraryname ) {
		warn("Could not parse real libary name for $libname. Shared library may fail in distribution");
		chmod( $storedmode, $targetfile );
		return;
	}

	my $installlibraryid = $newprefix . '/' . $truelibraryname;

	my $updateidcommand = 'install_name_tool -id ' . $installlibraryid . ' "' . $targetfile . '"';
	qx($updateidcommand);
	{
		@outputlines = qx($idcommand);
		unless ( scalar @outputlines ) {
			warn("Could not confirm ID update for $libname. Shared library may fail in distribution");
			chmod( $storedmode, $targetfile );
			return;
		}
		my $success = 0;
		for my $oline (@outputlines) {
			chomp $oline;
			if ( $oline eq $installlibraryid ) {
				$success = 1;
				last;
			}
		}
		if ( !$success ) {
			warn(
				"Could not confirm ID update for $libname after ID update complete. Shared library may fail in distribution"
			);
			chmod( $storedmode, $targetfile );
			return;
		}
	}

	#---------------------------------------------------
	# UPDATE THE FRAMEWORK DEPENDENCIES
	# --------------------------------------------------
	my $libidcommand = 'otool -LX "' . $targetfile . '"| grep -e ' . qq('$fworkprefix') . ' | cut -d " " -f 1';
	{
		@outputlines = qx($libidcommand);
		%seenlines   = ();
		for my $oline (@outputlines) {
			chomp($oline);
			next if ( exists( $seenlines{$oline} ) );
			$seenlines{$oline} = 1;
			next if $oline =~ /\Q$installlibraryid\E/;
			$oline =~ s/^\s+//;
			$oline =~ s/\s+$//;
			my $originaldependencypath = $oline;
			my @libpaths               = split( /\//, $originaldependencypath );
			my $depfilename            = $libpaths[-1];
			next if $depfilename !~ /^\Q$fworkprefix\E/;
			my $newdependencypath = $newprefix . '/' . $depfilename;
			my $updatedepencycommand =
				qq(install_name_tool -change \"$originaldependencypath\" \"$newdependencypath\" \"$targetfile\");
			qx($updatedepencycommand);
			my $success    = 0;
			my @checklines = qx($libidcommand);

			for my $checkline (@checklines) {
				chomp($checkline);
				if ( $checkline =~ /\Q$newdependencypath\E/ ) {
					$success = 1;
					last;
				}
			}
			if ( !$success ) {
				warn("Could not confirm dependency update for $libname");
			}
		}
	}
	chmod( $storedmode, $targetfile );
}


sub stc_install_scintilla_bundle {
	my ($self) = @_;

	# Set Params
	my $fworkprefix = $self->stc_framework_prefix;
	my $targetfile  = File::Spec->catfile( $self->install_destination('arch'), 'auto/Wx/Scintilla/Scintilla.bundle' );
	my $newprefix   = File::Spec->catfile( $self->install_destination('arch'), 'auto/Wx/Scintilla' );

	my $storedmode = ( stat($targetfile) )[2];
	my $newmode    = $storedmode | 0220;
	chmod( $newmode, $targetfile );

	my $libidcommand = 'otool -LX "' . $targetfile . '"| grep -e ' . qq('$fworkprefix') . ' | cut -d " " -f 1';
	{
		my @outputlines = qx($libidcommand);
		my %seenlines   = ();
		for my $oline (@outputlines) {
			chomp($oline);
			next if ( exists( $seenlines{$oline} ) );
			$seenlines{$oline} = 1;
			$oline =~ s/^\s+//;
			$oline =~ s/\s+$//;
			my $originaldependencypath = $oline;
			my @libpaths               = split( /\//, $originaldependencypath );
			my $depfilename            = $libpaths[-1];
			next if $depfilename !~ /^\Q$fworkprefix\E/;
			my $newdependencypath = $newprefix . '/' . $depfilename;
			my $updatedepencycommand =
				qq(install_name_tool -change \"$originaldependencypath\" \"$newdependencypath\" \"$targetfile\");
			qx($updatedepencycommand);
			my $success    = 0;
			my @checklines = qx($libidcommand);

			for my $checkline (@checklines) {
				chomp($checkline);
				if ( $checkline =~ /\Q$newdependencypath\E/ ) {
					$success = 1;
					last;
				}
			}
			if ( !$success ) {
				warn("Could not confirm dependency update for $targetfile");
			}
		}
	}

	chmod( $storedmode, $targetfile );
}


1;
