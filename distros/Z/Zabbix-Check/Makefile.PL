use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
	NAME				=> 'Zabbix::Check',
	VERSION_FROM		=> 'lib/Zabbix/Check.pm',
	MIN_PERL_VERSION	=> '5.014',
	PREREQ_PM			=> { 
		'Switch' => 0,
		'FindBin' => 0,
		'Cwd' => 0,
		'File::Basename' => 0,
		'File::Slurp' => 0,
		'JSON' => 0,
		'Net::NTP' => 0,
		'Lazy::Utils' => '1.04',
	},
	EXE_FILES			=> [qw(
	)],
	AUTHOR				=> 'Orkun Karaduman <orkunkaraduman@gmail.com>',
	ABSTRACT			=> 'System and service checks for Zabbix',
	LICENSE				=> 'gpl_3',
	META_MERGE			=> {
		'meta-spec' => {
			version => 2
		},
		resources => {
			homepage   => 'https://metacpan.org/release/Zabbix-Check',
			license    => 'https://www.gnu.org/licenses/gpl-3.0.html',
			repository => {
				type => 'git',
				url => 'git://git@github.com:orkunkaraduman/Zabbix-Check.git',
				web => 'https://github.com/orkunkaraduman/Zabbix-Check',
			},
			bugtracker => {
				web    => 'https://github.com/orkunkaraduman/Zabbix-Check/issues',
				mailto => 'bug-Zabbix-Check@rt.cpan.org',
			},
		},
	},
);
