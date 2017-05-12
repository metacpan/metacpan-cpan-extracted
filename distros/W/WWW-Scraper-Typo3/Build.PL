use Module::Build;

Module::Build -> new
(
	module_name    => 'WWW::Scraper::Typo3',
	license        => 'artistic',
	dist_abstract  => 'Clean up Typo3-based web site files',
	dist_author    => 'Ron Savage <ron@savage.neet.au>',
	build_requires =>
	{
		Test::More => 0,
		Test::Pod  => 0,
	},
	requires =>
	{
		common::sense     => 3.0,
		File::chdir       => 0.1003,
		File::Copy        => 2.11,
		File::Slurp       => 9999.13,
		File::Temp        => 0,
		HTML::TreeBuilder => 3.23,
		LWP::Simple       => 5.827,
		Moose             => 1.09,
	},
) -> create_build_script();
