# -*- mode: perl; c-basic-offset: 4; indent-tabs-mode: nil; -*-
use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile1(
	NAME             => 'Tk::ToolBar',
	VERSION_FROM     => 'lib/Tk/ToolBar.pm',
	PREREQ_PM        => {
		'Tk' => 0,
		# Don't define as strict dependency because Tk::CursorControl is not available always.
		# E.g. ActiveState Perl frequently lacks this package, avoiding this module to be build for PPM.
		#'Tk::CursorControl' => 0,
	},
	BUILD_REQUIRES => {
		'Test' => 0,
	},
	ABSTRACT_FROM => 'lib/Tk/ToolBar.pm',
	AUTHOR => 'Ala Qumsieh <aqumsieh@cpan.org>',
	LICENSE => 'perl',
	MIN_PERL_VERSION => '5.005',
	META_MERGE => {
		resources => {
			repository => 'http://github.com/chorny/Tk-ToolBar',
		},
	},
    $^O =~/win/i ? (
        dist => {
            TAR      => 'ptar',
            TARFLAGS => '-c -C -f',
        },
    ) : (),
	PM               => {
		'lib/Tk/ToolBar.pm'       => '$(INST_LIB)/Tk/ToolBar.pm',
		'toolbar.pl'       => ($] >= 5.005 ? '$(INST_ARCHLIB)' : '$(INST_LIB)') . '/Tk/demos/widtrib/toolbar.pl',
		'ToolBar/tkIcons'  => '$(INST_LIB)/Tk/ToolBar/tkIcons',
	},
);

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
}

