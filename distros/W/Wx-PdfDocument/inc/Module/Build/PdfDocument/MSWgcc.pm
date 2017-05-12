package Module::Build::PdfDocument::MSWgcc;

use 5.008;
use strict;
use warnings;
use Module::Build::PdfDocument::MSW;

use Config;

our @ISA = qw( Module::Build::PdfDocument::MSW );

sub _wxpdf_get_mingw_make {
    my $self = shift;
    return $self->{gccmingwmake} if defined($self->{gccmingwmake});
    my $makeres = qx(gmake --version 2>&1);
    if( $? ) {
        $self->{gccmingwmake} = 'mingw32-make';
    } else {
        $self->{gccmingwmake} = 'gmake';
    }
    $self->log_info(qq(GCC make is $self->{gccmingwmake}\n));
    return $self->{gccmingwmake};
}

sub wxpdf_built_libdir {
	my $self = shift;
	return $self->wxpdf_libdirectory . '/lib/gcc_dll';
}

sub wxpdf_pdfdocument_lib {
	my $self    = shift;
	my $libname = 'lib' . $self->wxpdf_pdfdocument_dll;
	$libname =~ s/\.dll$/\.a/i;
	return $libname;
}

sub wxpdf_pdfdocument_link {
	my $self    = shift;
	my $linkname = '-l' . $self->wxpdf_pdfdocument_dll;
	$linkname =~ s/\.dll$//i;
	return $linkname;
}

sub wxpdf_build_pdfdocument {
    my ( $self ) = @_;
    my $make = $self->_wxpdf_get_mingw_make;
    my $target = $self->notes( 'pdfdoc-build-target' );
    $self->wxpdf_win32_runpdfmakefile( qq($make $target), 'gcc', 'g++', ' -shared');
}

sub wxpdf_build_xs {
	my ($self) = @_;

	# Do not build XS if it is up to date
	return if $self->up_to_date( 'PdfDocument.c', 'PdfDocument.o' );

	my $dist_version = $self->dist_version;
	
	my $cflags = Alien::wxWidgets->c_flags;
	unless( Alien::wxWidgets->config->{debug} ) {
		$cflags .=  ' -DwxDEBUG_LEVEL=0 -DNDEBUG';
	}

	my @cmd = (
		Alien::wxWidgets->compiler,
		' -c -o PdfDocument.o',
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

	#$self->log_info("    ExtUtils::Mksymlists PdfDocument\n");

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

	# following lines should leave 'perl5xx.lib' unchanged
	$perllib =~ s/^lib/-l/;
	$perllib =~ s/\.a$//;

	# if perl lib is MS link lib perl5xx.lib, we need to prefix fullpath
	if ( $perllib =~ /\.lib$/i ) {
		$perllib = $Config{archlibexp} . '/CORE/' . $perllib;
	}

	my @cmd = (
		Alien::wxWidgets->linker,
		Alien::wxWidgets->link_flags,
		$Config{ldflags},
		'-L.',
		'-shared -s -o ' . $dll,
		'PdfDocument.o',
		$perllib,
		'-L' . $self->wxpdf_built_libdir,
		$self->wxpdf_pdfdocument_link,
		Alien::wxWidgets->libraries(qw(core base xml )),
		$Config{perllibs},
		'PdfDocument.def',
	);

	$self->_run_command( \@cmd );
}



1;
