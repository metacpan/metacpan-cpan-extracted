package Module::Build::PdfDocument::GTK;

use 5.008;
use strict;
use warnings;
use Module::Build::PdfDocument;
use Config;

our @ISA = qw( Module::Build::PdfDocument );

sub wxpdf_pdfdocument_lib {''}

sub wxpdf_built_libdir {
	my $self = shift;
	return $self->wxpdf_libdirectory . '/lib';
}

sub wxpdf_link_paths {
	my $self    = shift;
	my $libpath = $Config{libpth};
	my @paths   = split( /\s+/, $libpath );
	return '-L' . join( ' -L', @paths );
}

sub wxpdf_pdfdocument_dll {
	my $self    = shift;
	my $dllname = $self->wxpdf_pdfdocument_link;
	$dllname =~ s/^-l/lib/;
	$dllname .= '.so.0.0.0';
	return $dllname;
}

sub wxpdf_pdfdocument_module_name {
	my $self    = shift;
	my $modulename = $self->wxpdf_pdfdocument_link;
	$modulename =~ s/^-l/lib/;
	$modulename .= '.so.0';
	return $modulename;
}

sub wxpdf_pdfdocument_link {
	my $self     = shift;
	my $linkname = '-lwxcode_gtk2';
	$linkname .= 'u' if Alien::wxWidgets->config->{unicode};
	$linkname .= 'd' if Alien::wxWidgets->config->{debug};
	$linkname .= '_pdfdoc-';
	my ( $major, $minor, $release ) = $self->wxpdf_version_split;
	$linkname .= $major . '.' . $minor;
	return $linkname;
}

sub wxpdf_pdfdocument_symlinks {
	my $self = shift;
	my $basename = $self->wxpdf_pdfdocument_link;
	$basename =~ s/^-l/lib/;
	my @links = (
		qq(${basename}.so.0),
		qq(${basename}.so),
	);
	return @links;
}

sub wxpdf_build_pdfdocument {
	my ( $self ) = @_;
	
	my ( $major, $minor, $release ) = $self->wxpdf_version_split;
	my $mainversion = $major . $minor;
	
	my $pdfbuildflags = ( Alien::wxWidgets->config->{unicode} ) ? '--enable-unicode' : '--disable-unicode';
	if( Alien::wxWidgets->config->{debug} ) {
		$pdfbuildflags .= ' --enable-debug';
	} else {
		$pdfbuildflags .= ' --disable-debug';
	}
	
	my $wxconfigflag = '--with-wx-config=' . $self->wxpdf_wxconfig;

	my @cmd = (
		'../configure',
		'--with-wxshared=yes',
		'--enable-shared',
		$pdfbuildflags,
		$wxconfigflag,
	);
	
	if( Alien::wxWidgets->config->{debug} ) {
		push(@cmd, 'CXXFLAGS="-DWXPDFDOC_INHERIT_WXOBJECT=1"');
	} else {
        push(@cmd, 'CXXFLAGS="-DwxDEBUG_LEVEL=0 -DNDEBUG -DWXPDFDOC_INHERIT_WXOBJECT=1"');
    }
	
	my $topdir = $self->wxpdf_libdirectory;
	my $makedir = qq($topdir/mypdfbuild);
	mkdir( $makedir , 0777 );
	
	chdir $makedir;
	my $target = $self->notes( 'pdfdoc-build-target' );
	
	$self->_run_command( \@cmd );
	$self->_run_command( [ qq(make $target) ] );
	chdir '../../';
	$self->wxpdf_install_pdflibrary;
}

sub wxpdf_prebuild_check {
	my $self      = shift;
	my $ld        = Alien::wxWidgets->linker;
	my $libstring = $self->wxpdf_extra_pdfdocument_libs;
	my $outfile   = 'pdf_checkdepends.out';
	my $command   = qq($ld -fPIC -shared $libstring -o $outfile);
	if ( system($command) ) {
		unlink($outfile);
		print qq(Check for gtk2 development libraries failed.\n);
		print qq(Perhaps you need to install package libgtk2.0-dev or the equivalent for your system.\n);
		print qq(You can ofcourse uninstall it later after the installation is complete.\n);
		print qq(The build cannot continue.\n);
		exit(1);
	}
	unlink($outfile);
	return 1;
}

sub wxpdf_extra_pdfdocument_libs {
	my $self   = shift;
	my $extras = '-lgtk-x11-2.0 -lgdk-x11-2.0 -latk-1.0 -lpangoft2-1.0 ';
	$extras .= '-lgdk_pixbuf-2.0 -lm -lpango-1.0 -lfreetype -lfontconfig -lgobject-2.0 ';
	$extras .= '-lgmodule-2.0 -lgthread-2.0 -lglib-2.0';
	return $extras;
}

sub wxpdf_build_xs {
	my ($self) = @_;

	my $dist_version = $self->dist_version;
	
	my $cflags = Alien::wxWidgets->c_flags;
	unless( Alien::wxWidgets->config->{debug} ) {
		$cflags .=  ' -DwxDEBUG_LEVEL=0 -DNDEBUG';
	}

	my @cmd = (
		Alien::wxWidgets->compiler,
		'-fPIC -c -o PdfDocument.o',
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
}

sub wxpdf_link_xs {
	my ( $self, $dll ) = @_;

	my @cmd = (
		Alien::wxWidgets->linker,
		Alien::wxWidgets->link_flags,
		$Config{lddlflags},
		'-fPIC -L.',
		'-s -o ' . $dll,
		'PdfDocument.o',
		'-Lblib/arch/auto/Wx/PdfDocument ' . $self->wxpdf_pdfdocument_link,
		Alien::wxWidgets->libraries(qw(core base xml)),
		$Config{perllibs},
		"-Wl,-rpath,'\$ORIGIN'",
	);

	$self->_run_command( \@cmd );

}

1;
