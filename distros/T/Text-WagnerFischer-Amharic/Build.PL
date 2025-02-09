use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name		=> 'Text::WagnerFischer::Amharic',
	dist_version_from	=> 'lib/Text/WagnerFischer/Amharic.pm',
	dist_author		=> 'Daniel Yacob <dyacob\@cpan.org>',
	dist_abstract		=> "The WagnerFischer Algorithm Applied to Amharic.",
	release_status		=> 'stable',
	configure_requires	=> { 'Module::Build' => 0.42 },
	requires 		=> {
		'perl'			=> '5.8.0',
		'Regexp::Ethiopic'	=> '0.06',
		'Text::WagnerFischer' => '0.03'
	},
	license			=> 'perl',
	add_to_cleanup		=> [ 'Text-*' ],
	create_makefile_pl	=> 0,  # change to 1 if desired.
	meta_merge		=> {
        	resources => {
			bugtracker => 'https://github.com/dyacob/Text-WagnerFischer-Amharic/issues',
			repository => 'https://github.com/dyacob/Text-WagnerFischer-Amharic.git',
			homepage => 'https://github.com/dyacob/Text-WagnerFischer-Amharic'
		},
		x_authority	=> 'cpan:dyacob'
	}
);

$builder->create_build_script();
