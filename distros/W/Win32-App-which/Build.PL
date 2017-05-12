use 5.008;
exit 0 if $^O ne 'MSWin32' && !$ENV{RELEASE_BUILD};
use strict;
use warnings;
use Module::Build;
use utf8;

my $build = Module::Build->new(
    dist_name => 'Win32-App-which',
    module_name => 'Win32::App::which',
    dist_abstract => 'which Unix classic command for Windows',
    dist_author => 'Olivier Mengué <dolmen@cpan.org>',
    ( Module::Build->VERSION gt '0.37' ? (release_status => 'stable') : () ),
    # license => 'gpl_3', # Blocked by bug RT#66757 in Module::Build
    license => 'perl',
    meta_merge => {
	resources => {
	    # See bug RT#66758
	    license => 'http://www.gnu.org/licenses/gpl-3.0.html',
	    repository => 'https://github.com/dolmen/p5-Win32-App-which.git',
	},
    },

    #script_files => 'which.cmd',

    conflicts => {
	# Conflicts with ppt-0.14, but this dist doesn't has a module against
	# which we could check the version
    },
    requires => {
	perl => '5.008',
    },

    dynamic_config => 0,
    configure_requires => {
	# Some old M::B created additional files
	'Module::Build' => '0.3800',
    },
    build_requires => {
	'Test::More' => '0',
    },

    add_to_cleanup => [ 'bin/which.cmd~' ],
);

$build->create_build_script;
