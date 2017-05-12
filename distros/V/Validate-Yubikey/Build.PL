use Module::Build;
Module::Build->new(
	module_name => 'Validate::Yubikey',
	license => 'perl',
	requires => {
		perl => '5.6.1',
		'Crypt::Rijndael' => '1.09',
	},
)->create_build_script();
