use Module::Build;

Module::Build -> new
(
	module_name	=> 'XMail::Install',
	license		=> 'artistic',
	dist_author	=> 'Ron Savage <ron@savage.net.au>',
	build_requires	=>
	{
		Test::More	=> 0,
		Test::Pod	=> 0,
	},
	requires	=>
	{
		Carp					=> 0,
		Email::Send				=> 0,
		File::Copy				=> 0,
		File::Copy::Recursive	=> 0,
		File::Path				=> 0,
		Mail::POP3Client		=> 0,
		Path::Class				=> 0,
		Win32					=> 0,
		Win32::Process			=> 0,
		Win32::Process::List	=> 0,
		Win32::Service			=> 0,
		Win32::TieRegistry		=> 0,
	},
) -> create_build_script();