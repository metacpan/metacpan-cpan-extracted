use Module::Build;

Module::Build -> new
(
	module_name    => 'jQuery::File::Upload::Imager',
	license        => 'artistic_2',
	dist_abstract  => 'Server-side solution for blueimp jQuery file upload plugin',
	dist_author    => 'q{Adam Hopkins <srchulo@cpan.org>}',
	build_requires =>
	{
		Test::More=> 0.96,
#		Test::Pod  => 1.45, # Make it optional. See t/pod.t
	},
	configure_requires =>
	{
		Module::Build => 0.3800,
	},
	requires =>
	{
		CGI             => 3.63,
		Cwd             => 0,
		Digest::MD5     => 2.52,
		Imager          => 0.96,
		JSON::XS        => 2.34,
		Net::SSH2       => 0.48,
		Net::SSH2::SFTP => undef,
		strict          => 0,
		URI             => 1.60,
		warnings        => 0,
	},
) -> create_build_script();
