use strict;
use warnings;
use ExtUtils::MakeMaker;


WriteMakefile(
	NAME				=> 'Zabbix::Check',
	VERSION_FROM		=> 'lib/Zabbix/Check.pm',
	MIN_PERL_VERSION	=> '5.010001',
	PREREQ_PM			=> {
		'JSON'			=> '2.90',
		'Net::NTP'		=> '1.5',
		'Lazy::Utils'	=> '1.22',
	},
	EXE_FILES			=> [qw(
	)],
	AUTHOR				=> 'Orkun Karaduman <orkunkaraduman@gmail.com>',
	ABSTRACT			=> 'System and service checks for Zabbix',
	LICENSE				=> 'gpl_3',
	META_MERGE			=> {
		'meta-spec'		=> {
			version		=> 2
		},
		resources		=> {
			homepage	=> 'https://metacpan.org/release/Zabbix-Check/tree/master',
			license		=> 'https://www.gnu.org/licenses/gpl-3.0.html',
			repository	=> {
				type	=> 'git',
				url		=> 'git://git@github.com:orkunkaraduman/Zabbix-Check.git',
				web		=> 'https://github.com/orkunkaraduman/Zabbix-Check',
			},
			bugtracker => {
				web		=> 'https://github.com/orkunkaraduman/Zabbix-Check/issues',
				mailto	=> 'bug-Zabbix-Check@rt.cpan.org',
			},
		},
	},
);
