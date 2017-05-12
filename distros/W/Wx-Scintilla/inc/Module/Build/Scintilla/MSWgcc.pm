package Module::Build::Scintilla::MSWgcc;

use 5.006;
use strict;
use warnings;
use Module::Build::Scintilla::MSW;

use Config;

our @ISA = qw( Module::Build::Scintilla::MSW );

sub stc_scintilla_lib {
	my $self    = shift;
	my $libname = 'libwxmsw';
	my ( $major, $minor, $release ) = $self->stc_version_strings;
	$libname .= $major . $minor;
	$libname .= $release if $release;
	$libname .= 'u' if Alien::wxWidgets->config->{unicode};
	$libname .= 'd' if Alien::wxWidgets->config->{debug};
	$libname .= '_scintilla.a';
	return $libname;
}

sub stc_scintilla_dll {
	my $self    = shift;
	my $dllname = 'wxmsw';
	my ( $major, $minor, $release ) = $self->stc_version_strings;
	$dllname .= $major . $minor;
	$dllname .= $release if $release;
	$dllname .= 'u' if Alien::wxWidgets->config->{unicode};
	$dllname .= 'd' if Alien::wxWidgets->config->{debug};
	$dllname .= '_scintilla_gcc.dll';
	return $dllname;
}

sub stc_scintilla_link {
	my $class    = shift;
	my $linkname = '-lwxmsw';
	my ( $major, $minor, $release ) = $class->stc_version_strings;
	$linkname .= $major . $minor;
	$linkname .= $release if $release;
	$linkname .= 'u' if Alien::wxWidgets->config->{unicode};
	$linkname .= 'd' if Alien::wxWidgets->config->{debug};
	$linkname .= '_scintilla';
	return $linkname;
}

sub stc_build_scintilla_object {
	my ( $self, $module, $object_name, $includedirs ) = @_;

	my @cmd = (
		$self->stc_compiler,
		$self->stc_ccflags,
		$self->stc_defines,
		( $Config{ptrsize} == 8 ) ? '-DWIN32 -DWIN64' : '-DWIN32',
		'-o ' . $object_name,
		'-O2',
		'-Wall',
		$object_name !~ /((Plat|Scintilla)WX|scintilla)\.o/
		? '-Wno-missing-braces -Wno-char-subscripts'
		: '',
		'-MT' . $object_name,
		'-MF' . $object_name . '.d',
		'-MD -MP',
		join( ' ', @$includedirs ),
		$module,
	);

	$self->_run_command( \@cmd );
}

sub stc_link_scintilla_objects {
	my ( $self, $shared_lib, $objects ) = @_;

	my @cmd = (
		$self->stc_linker,
		$self->stc_ldflags,
		'-shared -o ' . $shared_lib,
		join( ' ', @$objects ),
		'-Wl,--out-implib=' . $self->stc_scintilla_lib,
		'-lgdi32 -luser32',
		Alien::wxWidgets->libraries(qw(core base)),
	);

	$self->_run_command( \@cmd );
}

sub stc_build_xs {
	my ($self) = @_;

	# Do not build XS if it is up to date
	return if $self->up_to_date( 'Scintilla.c', 'Scintilla.o' );

	my $dist_version = $self->dist_version;

	my @cmd = (
		Alien::wxWidgets->compiler,
		' -c -o Scintilla.o',
		'-I.',
		'-I' . $self->stc_get_wx_include_path,
		'-I' . $Config{archlibexp} . '/CORE',
		Alien::wxWidgets->include_path,
		Alien::wxWidgets->c_flags,
		Alien::wxWidgets->defines,
		$Config{ccflags},
		$Config{optimize},
		'-DWXPL_EXT -DVERSION=\"' . $dist_version . '\" -DXS_VERSION=\"' . $dist_version . '\"',
		'Scintilla.c',
	);

	$self->_run_command( \@cmd );

	$self->log_info("    ExtUtils::Mksymlists Scintilla\n");

	require ExtUtils::Mksymlists;
	ExtUtils::Mksymlists::Mksymlists(
		'NAME'     => 'Wx::Scintilla',
		'DLBASE'   => 'Scintilla',
		'DL_FUNCS' => {},
		'FUNCLIST' => [],
		'IMPORTS'  => {},
		'DL_VARS'  => []
	);

}

sub stc_link_xs {
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
		'Scintilla.o',
		$perllib,
		$self->stc_scintilla_link,
		Alien::wxWidgets->libraries(qw(core base)),
		$Config{perllibs},
		'Scintilla.def',
	);

	$self->_run_command( \@cmd );
}



1;
