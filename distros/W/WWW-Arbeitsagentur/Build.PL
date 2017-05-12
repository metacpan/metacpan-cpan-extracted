use Module::Build;

Module::Build->new(
		   module_name	=> 'WWW::Arbeitsagentur',
		   license	=> 'perl',
		   dist_author	=> 'Ingo Wiarda',
#		   dist_version_from => 'WWW::Arbeitsagentur',
		   requires	=> {
		       'Digest::SHA'	=> '5.34',
		       'WWW::Mechanize' => '1.18',
		       'HTTP::Cookies' => '1.39',
		   },
		   create_readme => 1,
		   )->create_build_script;
