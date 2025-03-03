use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name		=> 'Text::TransMetaphone',
	dist_version_from	=> 'lib/Text/TransMetaphone.pm',
	dist_author		=> 'Daniel Yacob <dyacob\@cpan.org>',
	dist_abstract		=> "Translingual Phonetic Encoding of Words.",
	release_status		=> 'stable',
	configure_requires	=> { 'Module::Build' => 0.42 },
	requires		=> { 'Regexp::Ethiopic' => 0 },
	license			=> 'perl',
	add_to_cleanup		=> [ 'Text-Transmetaphone-*' ],
	create_makefile_pl	=> 0,  # change to 1 if desired.
	meta_merge		=> {
        	resources => {
			bugtracker => 'https://github.com/dyacob/Text-TransMetaphone/issues',
			repository => 'https://github.com/dyacob/Text-TransMetaphone.git',
			homepage => 'https://github.com/dyacob/Text-TransMetaphone'
		},
		x_authority	=> 'cpan:dyacob'
	},
);

$builder->create_build_script();
