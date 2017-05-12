use Module::Build;

my $build = Module::Build->new(
	module_name => 'WWW-Shopify-Tools-Themer',
	license => 'perl',
	dist_author => 'Adam Harrison <adamdharrison@gmail.com>',
	dist_version_from => 'lib/WWW/Shopify/Tools/Themer.pm',
	dist_abstract => 'Support for theme modification, either through scripting or through gedit plugin.',
	configure_requires => {
		'Module::Build' => 0.38,
	},
	share_dir => ['assets'],
	requires => {
		'LWP::Simple' => 0,
		'File::Path' => 0,
		'File::Find' => 0,
		'File::stat' => 0,
		'JSON' => 0,
		'Test::More' => 0,
		'MIME::Base64' => 0,
		'Getopt::Long' => 0,
		'IO::Handle' => 0,
		'File::Basename' => 0,
		'Cwd' => 0,
		'File::ShareDir' => 0,
		'Term::Prompt' => 0,
		'Pod::Usage' => 0,
		'WWW::Shopify' => 0.9,
	},
	script_files => ['shopify-themer.pl']
);
$build->create_build_script;
