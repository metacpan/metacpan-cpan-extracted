use 5.006001;
use ExtUtils::MakeMaker;
use ExtUtils::Liblist;

#
# Do not try to build on systems /known/ not to work
#
if (grep { $^O eq $_ } qw(irix solaris MSWin32 msys)) {
	print("OS unsupported\n");
	exit(0);
}

#
# Check for call "getgrouplist".
#
# No false negatives known yet. Please contact author if your system provides
# a getgrouplist but is still rejected here.
#
use lib 'inc/';
use Devel::CheckLib;
check_lib_or_exit(
	function => '
		struct group *gr; gid_t groups[2]; int n = 1;
		getgrouplist("foo", 123, groups, &n);
		return 0;
	',
	lib	=> 'c',
	header	=> 'grp.h',

);


WriteMakefile(
    NAME                => 'User::getgrouplist',
    AUTHOR              => 'Bastian Friedrich <bastian.friedrich@collax.com>',
    VERSION_FROM        => 'lib/User/getgrouplist.pm',
    ABSTRACT_FROM       => 'lib/User/getgrouplist.pm',
    PREREQ_PM           => {
        'Exporter'      => 0,
        'Test::More'    => 0,
        'Test::Builder' => 0,
    },

    NEEDS_LINKING       => 1,
    INC                 => '-I.',

    EXE_FILES           => [],
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'User-getgrouplist-*.tar.*' },
);
