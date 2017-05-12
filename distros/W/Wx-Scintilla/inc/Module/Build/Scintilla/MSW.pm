package Module::Build::Scintilla::MSW;

use 5.006;
use strict;
use warnings;
use Module::Build::Scintilla;
use Config;

our @ISA = qw( Module::Build::Scintilla );

sub stc_linker {
	my $self = shift;
	return Alien::wxWidgets->linker;
}

sub stc_ldflags {
	my $self = shift;
	return Alien::wxWidgets->link_flags;
}

sub stc_compiler {
	my $self = shift;
	return Alien::wxWidgets->compiler . ' -c';
}

sub stc_ccflags {
	my $self  = shift;
	my $flags = Alien::wxWidgets->c_flags;
	return $flags;
}

sub stc_scintilla_lib {
	my $self    = shift;
	my $libname = $self->stc_scintilla_dll;
	$libname =~ s/\.dll$/\.lib/i;
	return $libname;
}

sub stc_scintilla_dll {
	my $self    = shift;
	my $dllname = 'wxmsw';
	my ( $major, $minor, $release ) = $self->stc_version_strings;
	$dllname .= $release if $release;
	$dllname .= 'u' if Alien::wxWidgets->config->{unicode};
	$dllname .= 'd' if Alien::wxWidgets->config->{debug};
	$dllname .= '_scintilla_vc.dll';
	return $dllname;
}

sub stc_scintilla_link { $_[0]->stc_scintilla_lib; }

sub stc_build_scintilla_object {
	my ( $self, $module, $object_name, $includedirs ) = @_;

	my @cmd = (
		$self->stc_compiler,
		$self->stc_ccflags,
		$self->stc_defines,
		( $Config{ptrsize} == 8 ) ? '-O2 -MD -DWIN32 -DWIN64' : '-O2 -MD -DWIN32',
		'/nologo /TP /Fo' . $object_name,
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
		"wx-scintilla/src/*.obj",
		"wx-scintilla/src/scintilla/src/*.obj",
		"/DLL /NOLOGO /OUT:$shared_lib",
		'/LIBPATH:"' . Alien::wxWidgets->shared_library_path . '"',

		Alien::wxWidgets->link_libraries(qw(core base)),
		'gdi32.lib user32.lib',
	);

	$self->_run_command( \@cmd );

}

sub stc_build_xs {
	my ($self) = @_;

	# Do not build XS if it is up to date
	return if $self->up_to_date( 'Scintilla.c', 'Scintilla.obj' );

	my $dist_version = $self->dist_version;

	my @cmd = (
		Alien::wxWidgets->compiler,
		' /c /FoScintilla.obj',
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

	$self->log_info("Running Mkbootstrap for Wx::Scintilla\n");

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

	my @cmd = (
		Alien::wxWidgets->linker,
		Alien::wxWidgets->link_flags,
		$Config{lddlflags},
		'-out:' . $dll,
		'Scintilla.obj',
		'blib/arch/auto/Wx/Scintilla/' . $self->stc_scintilla_link,
		$perllib,
		Alien::wxWidgets->libraries(qw(core base)),
		'/LIBPATH:"' . Alien::wxWidgets->shared_library_path . '"',
		$Config{perllibs},
		'-def:Scintilla.def',
	);

	$self->_run_command( \@cmd );

}

1;
