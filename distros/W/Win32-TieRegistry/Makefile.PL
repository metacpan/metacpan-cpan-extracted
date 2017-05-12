use 5.006;
use strict;
use ExtUtils::MakeMaker;

# Don't prevent this running on Win32.
# THIS distribution is inherantly platform-neutral, but the underlying
# dependency is not. Allow non-Win32 platforms to fail on our dependency,
# instead of on this module. This allows any unusual cases like Wine
# (that are able to get the dependency installed) to install this ok.

WriteMakefile1(
	'NAME'         => 'Win32::TieRegistry',
	'ABSTRACT'     => 'Manipulate the Win32 Registry',
	'VERSION_FROM' => 'lib/Win32/TieRegistry.pm',
	'LICENSE'      => 'perl',
	'PREREQ_PM'    => {
		'Carp'               => 0,
		'Tie::Hash'          => 0,
		'Win32::WinError'    => 0,

		# If we are upgrading Win32::TieRegistry,
		# then we want to also force the upgrade
		# of the underlying module.
		'Win32API::Registry' => '0.33',
	},
	MIN_PERL_VERSION => '5.006',
	TEST_REQUIRES => {
		'Test::More'         => '0.42',
	},
	META_MERGE => {
		resources => {
			repository => 'git://github.com/chorny/Win32-TieRegistry.git',
		},
	},
    $^O =~/win/i ? (
        dist => {
            TAR      => 'ptar',
            TARFLAGS => '-c -C -f',
        },
    ) : (),
);


sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
	my %params=@_;
	my $eumm_version=$ExtUtils::MakeMaker::VERSION;
	$eumm_version=eval $eumm_version;
	die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
	die "License not specified" if not exists $params{LICENSE};
	if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
		$params{META_ADD}->{author}=$params{AUTHOR};
		$params{AUTHOR}=join(', ',@{$params{AUTHOR}});
	}
	if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
		$params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
		delete $params{TEST_REQUIRES};
	}
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

	WriteMakefile(%params);
}

