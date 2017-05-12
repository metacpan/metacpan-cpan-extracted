package Module::Build::PdfDocument::MSW;

use 5.008;
use strict;
use warnings;
use Module::Build::PdfDocument;
use Config;

our @ISA = qw( Module::Build::PdfDocument );

sub wxpdf_built_libdir {
	my $self = shift;
	return $self->wxpdf_libdirectory . '/lib/vc_dll';
}

sub wxpdf_linker {
	my $self = shift;
	return Alien::wxWidgets->linker;
}

sub wxpdf_ldflags {
	my $self = shift;
	return Alien::wxWidgets->link_flags;
}

sub wxpdf_compiler {
	my $self = shift;
	return Alien::wxWidgets->compiler . ' -c';
}

sub wxpdf_ccflags {
	my $self  = shift;
	my $flags = Alien::wxWidgets->c_flags;
	return $flags;
}

sub wxpdf_pdfdocument_lib {
	my $self    = shift;
	my $libname = $self->wxpdf_pdfdocument_dll;
	$libname =~ s/\.dll$/\.lib/i;
	return $libname;
}

sub wxpdf_pdfdocument_dll {
	my $self    = shift;
	my $dllname = 'wxcode_msw';
	my ( $major, $minor, $release ) = $self->wxpdf_version_split;
	$dllname .= $major . $minor;
	$dllname .= 'u' if Alien::wxWidgets->config->{unicode};
	$dllname .= 'd' if Alien::wxWidgets->config->{debug};
	$dllname .= '_pdfdoc.dll';
	return $dllname;
}

sub wxpdf_pdfdocument_module_name {
	my $self    = shift;
	$self->wxpdf_pdfdocument_dll;
}

sub wxpdf_pdfdocument_link { $_[0]->wxpdf_pdfdocument_lib; }

sub wxpdf_pdfdocument_symlinks { return (); }

sub wxpdf_build_pdfdocument {
	my ( $self, $distdir  ) = @_;
    my $target = $self->notes( 'pdfdoc-build-target' );
	$self->wxpdf_win32_runpdfmakefile(qq(nmake $target), 'vc', 'cl', undef);
}

sub wxpdf_win32_runpdfmakefile {
	my ( $self, $make, $compiler, $cpp, $lddlflags ) = @_;
	
	my $wxbasepath = Alien::wxWidgets->prefix;
	
	my ( $major, $minor, $release ) = $self->wxpdf_version_split;
	my $wxshortver = $major . $minor;
	#my $makefile = qq(makefile${wxshortver}.${compiler});
    my $makefile = qq(makefile.${compiler});
	my $builddir = ( $wxshortver eq '28' ) ? 'build28' : 'build';
	
	#{
	#	my $targetfile = $self->wxpdf_libdirectory . qq(/$builddir/$makefile);
	#	unlink $targetfile if -f $targetfile;
	#	File::Copy::copy(qq(msw/files/$makefile), $targetfile) or die qq(Failed to copy $targetfile : $!);
	#}
    
	my %makevals = (
		LINK_DLL_FLAGS => $lddlflags,
		CXX 		   => $cpp,
		CXXFLAGS	   => undef,
		CPPFLAGS	   => undef,
		LDFLAGS 	   => undef,
		SHARED         => 1,
		WX_SHARED      => 1,
		WX_UNICODE     => 1,
		WX_DEBUG       => 0,
		WX_VERSION 	   => $wxshortver,
		WX_MONOLITHIC  => 0,
		Wx_DIR         => undef,
		WXPERL_STATIC_DIR => ( $Config::Config{ptrsize} == 8 ) ? 'x64' : 'x86', 
	);
	
	my %cfgvals = (
		MONOLITHIC	=> 0, 
		SHARED		=> 1, 
	    UNICODE		=> 1, 
		CFLAGS		=> undef, 
		CPPFLAGS    => undef, 
		CXXFLAGS	=> undef, 
		LDFLAGS		=> undef, 
	);
	
	my $alienroot = Alien::wxWidgets->prefix;
	my $buildcfg = qq($alienroot/lib/build.cfg);
	my @basecommands = qw( -f );
	
	if( -f $buildcfg ) {
		open my $fh, '<', $buildcfg or die qq(Could not open $buildcfg : $!);
		while(<$fh>) {
			chomp;
			my $line = $_;
			$line =~ s/^\s+//;
			$line =~ s/\s+$//;
			next unless $line;
			next if $line =~ /^#/;
			next if $line !~ /=/;
			my( $key, $value ) = split(/\s*=\s*/, $line );
			if( defined($value) && $value ne '' ) {
				$cfgvals{$key} = $value;
			}
		}
		close($fh);
		
		$makevals{LINK_DLL_FLAGS} = $cfgvals{LINK_DLL_FLAGS} if defined($cfgvals{LINK_DLL_FLAGS});
		$makevals{CXXFLAGS} = $cfgvals{CXXFLAGS} if defined $cfgvals{CXXFLAGS};
		$makevals{CPPFLAGS} = $cfgvals{CPPFLAGS} if defined $cfgvals{CPPFLAGS};
		$makevals{LDFLAGS} = $cfgvals{LDFLAGS} if defined $cfgvals{LDFLAGS};
		$makevals{SHARED} = $cfgvals{SHARED};
		$makevals{WX_SHARED} = $cfgvals{SHARED};
		$makevals{WX_UNICODE} = $cfgvals{UNICODE};
		$makevals{CFLAGS} = $cfgvals{CFLAGS} if defined $cfgvals{CFLAGS};
		$makevals{WX_MONOLITHIC} = $cfgvals{MONOLITHIC};
		$makevals{WX_DEBUG} = ( Alien::wxWidgets->config->{debug} ) ? 1 : 0;
		$makevals{WX_DIR} = $alienroot;
        
        $makevals{CXXFLAGS} .= ' -DWXPDFDOC_INHERIT_WXOBJECT=1';
        $makevals{CPPFLAGS} .= ' -DWXPDFDOC_INHERIT_WXOBJECT=1';
        $makevals{CFLAGS} .= ' -DWXPDFDOC_INHERIT_WXOBJECT=1';
		
	} else {
		die 'build.cfg not present';
	}
	
	my @configcommands = ();
	foreach my $key ( sort keys(%makevals) ) {
		if(defined($makevals{$key})) {
			$makevals{$key} = qq(\"$makevals{$key}\") if $makevals{$key} =~ /\s/;
			push( @configcommands, qq($key=$makevals{$key}) );
		}
	}
	
	my @commands = (
		$make,
		'-f',
		$makefile,
		@configcommands,
	);
	
	chdir $self->wxpdf_libdirectory . '/' . $builddir;
	$self->_run_command( \@commands );
	chdir '../../';
	
	$self->wxpdf_install_pdflibrary;
}

sub wxpdf_build_xs {
	my ($self) = @_;

	# Do not build XS if it is up to date
	return if $self->up_to_date( 'PdfDocument.c', 'PdfDocument.obj' );

	my $dist_version = $self->dist_version;
	
	my $cflags = Alien::wxWidgets->c_flags;
	unless( Alien::wxWidgets->config->{debug} ) {
		$cflags .=  ' -DwxDEBUG_LEVEL=0 -DNDEBUG';
	}

	my @cmd = (
		Alien::wxWidgets->compiler,
		' /c /FoPdfDocument.obj',
		'-I.',
		'-I' . $self->wxpdf_get_wx_include_path,
		'-I' . $Config{archlibexp} . '/CORE',
		'-I' . $self->wxpdf_libdirectory . '/include',
		Alien::wxWidgets->include_path,
		$cflags,
        '-DWXPDFDOC_INHERIT_WXOBJECT=1',
		Alien::wxWidgets->defines,
		$Config{ccflags},
		$Config{optimize},
		'-DWXPL_EXT -DVERSION=\"' . $dist_version . '\" -DXS_VERSION=\"' . $dist_version . '\"',
		'PdfDocument.c',
	);

	$self->_run_command( \@cmd );

	#$self->log_info("Running Mkbootstrap for Wx::PdfDocument\n");

	require ExtUtils::Mksymlists;
	ExtUtils::Mksymlists::Mksymlists(
		'NAME'     => 'Wx::PdfDocument',
		'DLBASE'   => 'PdfDocument',
		'DL_FUNCS' => {},
		'FUNCLIST' => [],
		'IMPORTS'  => {},
		'DL_VARS'  => []
	);

}

sub wxpdf_link_xs {
	my ( $self, $dll ) = @_;

	my $perllib = $Config{libperl};

	my @cmd = (
		Alien::wxWidgets->linker,
		Alien::wxWidgets->link_flags,
		$Config{lddlflags},
		'-out:' . $dll,
		'PdfDocument.obj',
        $self->wxpdf_built_libdir . '/' . $self->wxpdf_pdfdocument_link,
		$perllib,
		Alien::wxWidgets->libraries(qw(core base xml)),
		'/LIBPATH:"' . Alien::wxWidgets->shared_library_path . '"',
		$Config{perllibs},
        '-def:PdfDocument.def',
	);

	$self->_run_command( \@cmd );

}

sub wxpdf_prebuild_check {
	my $self = shift;
	my $alienversion = $Alien::wxWidgets::VERSION;
	
	if ( $alienversion < 0.65 ) {
		# make builtins available
		# from 0.65 onwards they are installed with Alien
		system(qq(MOVE /Y mswlibs msw));
	}
	
    return 1;
}

1;
