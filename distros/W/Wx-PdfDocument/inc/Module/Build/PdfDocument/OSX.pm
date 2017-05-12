package Module::Build::PdfDocument::OSX;

use 5.008;
use strict;
use warnings;
use Module::Build::PdfDocument;
use Config;
use Cwd;

our @ISA = qw( Module::Build::PdfDocument );

sub ACTION_install {
	my $self   = shift;
	my $result = $self->SUPER::ACTION_install(@_);
	$self->wxpdf_install_pdfdocument_library(File::Spec->catfile( $self->install_destination('arch'), 'auto/Wx/PdfDocument'));
	$self->wxpdf_install_pdfdocument_bundle(File::Spec->catfile( $self->install_destination('arch'), 'auto/Wx/PdfDocument'));
	return $result;
}

sub wxpdf_built_libdir {
	my $self = shift;
	return $self->wxpdf_libdirectory . '/lib';
}

sub wxpdf_linker {
	my $self    = shift;
	my $command = $self->wxpdf_wxconfig . ' --ld';
	my $linker  = qx($command);
	chomp($linker);

	# strip -o for macosx
	$linker =~ s/ -o\s*$//;
	return $linker;
}

sub wxpdf_pdfdocument_lib {''}

sub wxpdf_pdfdocument_macbasename {
	my $self = shift;
	my ( $major, $minor, $release ) = $self->wxpdf_version_split;
	my $mainver = $major . $minor;
	my $basename = ( $mainver eq '28' ) ? 'libwxcode_mac' : 'libwxcode_osx_cocoa';
	return $basename;
}

sub wxpdf_pdfdocument_link {
	my $self     = shift;
	my $linkname = $self->wxpdf_pdfdocument_macbasename;
	$linkname =~ s/^lib/-l/;
	$linkname .= 'u' if Alien::wxWidgets->config->{unicode};
	$linkname .= 'd' if Alien::wxWidgets->config->{debug};
	$linkname .= '_pdfdoc-';
	my ( $major, $minor, $release ) = $self->wxpdf_version_split;
	$linkname .= $major . '.' . $minor;
	return $linkname;
}

sub wxpdf_pdfdocument_dll {
	my $self    = shift;
	my $dllname = $self->wxpdf_pdfdocument_link;
	$dllname .= '.0.0.0.dylib';
	$dllname =~ s/^-l/lib/;
	return $dllname;
}

sub wxpdf_pdfdocument_module_name {
	my $self    = shift;
	my $modulename = $self->wxpdf_pdfdocument_link;
	$modulename .= '.0.dylib';
	$modulename =~ s/^-l/lib/;
	return $modulename;
}

sub wxpdf_pdfdocument_symlinks {
	my $self = shift;
	my $basename = $self->wxpdf_pdfdocument_link;
	$basename =~ s/^-l/lib/;
	my @links = (
		qq(${basename}.0.dylib),
		qq(${basename}.dylib),
	);
	return @links;
}


sub wxpdf_framework_prefix {
	my $self   = shift;
	my $prefix = $self->wxpdf_pdfdocument_macbasename;
	$prefix .= 'u' if Alien::wxWidgets->config->{unicode};
	$prefix .= 'd' if Alien::wxWidgets->config->{debug};
	$prefix .= '_pdfdoc';
	return $prefix;
}

sub wxpdf_build_pdfdocument {
	my ( $self ) = @_;

	my $cxxflags = $self->wxpdf_get_architecture_string;
	$cxxflags .= ' ' . $self->wxpdf_ccflags;
	$cxxflags .= ' ' . $self->wxpdf_defines;
	$cxxflags .= ' -Wl,-headerpad_max_install_names';
	my $ldflags = ' -headerpad_max_install_names';
	$ldflags .= ' ' . $self->wxpdf_ldflags,
	$ldflags .= ' ' . $self->wxpdf_get_architecture_string;
	
	my ( $major, $minor, $release ) = $self->wxpdf_version_split;
	my $mainversion = $major . $minor;
	
	my $pdfbuildflags = ( Alien::wxWidgets->config->{unicode} ) ? '--enable-unicode' : '--disable-unicode';
	if( Alien::wxWidgets->config->{debug} ) {
		$pdfbuildflags .= ' --enable-debug';
	} else {
		$pdfbuildflags .= ' --disable-debug';
		$cxxflags .= ' -DwxDEBUG_LEVEL=0 -DNDEBUG',
	}
	
	my $wxconfigflag = '--with-wx-config=' . $self->wxpdf_wxconfig;
	my $cflags = $Config{ccflags};
    $cflags =~ s/-nostdinc //g;
	$cxxflags .= ' ' . $cflags;
	
	my $ldxflags = $Config{ldflags};
    $ldxflags =~ s/-nostdinc //g;
	$ldflags .= ' ' . $ldxflags;
	
	my $cppflags = $self->wxpdf_get_architecture_string;
	$cppflags = '-arch ppc' if $cppflags =~ /ppc/;
	
	my $compiler = $self->_set_clang_args( Alien::wxWidgets->compiler );
	
	my $configcmd = '../configure';
	
	if ( $compiler =~ /clang\+\+/ ) {
		$compiler =~ s/clang\+\+\s+//;
		$cxxflags = $compiler . ' ' . $cxxflags;
		$ldflags = $compiler . ' ' . $ldflags;
		$cppflags = $compiler . ' ' . $cppflags;
		$configcmd .= ' CXX="clang++"';
	}
	
	my @cmd = (
		$configcmd,
        qq(--disable-dependency-tracking), # allow universal builds
		qq(CXXFLAGS=\"$cxxflags -DWXPDFDOC_INHERIT_WXOBJECT=1\"),
		qq(LDFLAGS=\"$ldflags\"),
		qq(CPPFLAGS=\"$cppflags -DWXPDFDOC_INHERIT_WXOBJECT=1\"),
		'--with-wxshared=yes',
		'--enable-shared',
		$pdfbuildflags,
		$wxconfigflag,
	);
	
	my $topdir = $self->wxpdf_libdirectory;
	my $makedir = qq($topdir/mypdfbuild);
	mkdir( $makedir , 0777 );
	
	chdir $makedir;
	
	my $target = $self->notes( 'pdfdoc-build-target' );
	
	$self->_run_command( \@cmd );
	$self->_run_command( [ qq(make $target) ] );
	chdir '../../';
	$self->wxpdf_install_pdflibrary;
	
	my $prefixpath = Cwd::realpath('blib/arch/auto/Wx/PdfDocument');
	#Allow Tests To Run
	$self->wxpdf_install_pdfdocument_library( $prefixpath );
}


sub wxpdf_build_xs {
	my ($self) = @_;

	# Do not build XS if it is up to date
	return if $self->up_to_date( 'PdfDocument.c', 'PdfDocument.o' );

	my $dist_version = $self->dist_version;

	# we must remove any nostdinc params
	my $ccflags = $Config{ccflags};
	$ccflags =~ s/-nostdinc //g;
	
	my $cflags = Alien::wxWidgets->c_flags;
	unless( Alien::wxWidgets->config->{debug} ) {
		$cflags .=  ' -DwxDEBUG_LEVEL=0 -DNDEBUG';
	}
	
	my $compiler = $self->_set_clang_args( Alien::wxWidgets->compiler );

	my @cmd = (
		$compiler,
		$self->wxpdf_get_architecture_string,
		' -c',
		'-I.',
		'-I' . $self->wxpdf_get_wx_include_path,
		'-I' . $Config{archlibexp} . '/CORE',
		'-I' . $self->wxpdf_libdirectory . '/include',
		Alien::wxWidgets->include_path,
		$cflags,
        '-DWXPDFDOC_INHERIT_WXOBJECT=1',
		Alien::wxWidgets->defines,
		$ccflags,
		$Config{optimize},
		'-DWXPL_EXT -DVERSION=\"' . $dist_version . '\" -DXS_VERSION=\"' . $dist_version . '\"',
		'PdfDocument.c',
	);

	$self->_run_command( \@cmd );
}


sub wxpdf_link_xs {
	my ( $self, $dll ) = @_;

	# we must remove any nostdinc params
	my $ldflags = $Config{lddlflags};
	$ldflags =~ s/-nostdinc //g;

	my $linker = $self->_set_clang_args( Alien::wxWidgets->linker );
	my $runcmd = $linker . ' ' . $self->wxpdf_get_architecture_string . ' ' . Alien::wxWidgets->link_flags;
	my $dllout = '-s -o ' . $dll;
	
	if ( $linker =~ /clang\+\+/ ) {
		$runcmd = $Config{ld};
		$dllout = '-o ' . $dll;
	}

	my @cmd = (
		$runcmd,
		'-headerpad_max_install_names',
		$ldflags,
		$dllout,
		'PdfDocument.o',
		'blib/arch/auto/Wx/PdfDocument/' . $self->wxpdf_pdfdocument_dll,
		Alien::wxWidgets->libraries(qw(core base xml)),
		$Config{perllibs},
	);

	$self->_run_command( \@cmd );
}

# We need our own run command to strip out none buildable architectures
sub _run_command {
	my $self = shift;
	my $cmds = shift;
	my $cmd  = join( ' ', @$cmds );

	my $archconf = $self->wxpdf_get_architectures;

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

sub wxpdf_get_architectures {
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

sub wxpdf_get_architecture_string {
	my $self       = shift;
	my $config     = $self->wxpdf_get_architectures;
	my $archstring = '';
	foreach my $arch ( sort keys(%$config) ) {
		$archstring .= qq(-arch $arch ) if $config->{$arch};
	}
	return $archstring;
}

sub wxpdf_install_pdfdocument_library {
	my ($self, $directory) = @_;

	# Set Params
	my $fworkprefix = $self->wxpdf_framework_prefix;
	my $libname     = $self->wxpdf_pdfdocument_dll;
	my $targetfile  = $directory . '/' . $libname;
	my $newprefix   = $directory;

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


sub wxpdf_install_pdfdocument_bundle {
	my ($self, $directory) = @_;

	# Set Params
	my $fworkprefix = $self->wxpdf_framework_prefix;
	my $targetfile  = $directory . '/PdfDocument.bundle';
	my $newprefix   = $directory;

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


sub _set_clang_args {
	my( $self, $instring ) = @_;
	
	if ($instring =~ /clang\+\+/) {
		my $sdkrepl = '';
		for my $sdkversion ( qw( 10.13 10.12 10.11 10.10 10.9 10.8 10.7 10.6 ) ) {
			my $macossdk = qq(/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX${sdkversion}.sdk);
			if( -d $macossdk ) {
				$sdkrepl = 'clang++ -isysroot ' . $macossdk . ' -stdlib=libc++';
				last;
			}
		}
		if ( $sdkrepl ) {
			$instring =~ s/clang\+\+/$sdkrepl/g;
			$instring =~ s/clang\+\+/$sdkrepl/g;
		}
	}
	
	return $instring;
}

1;
