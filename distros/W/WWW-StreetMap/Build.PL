use strict;
use Module::Build;

Module::Build->new(
	module_name        => 'WWW::StreetMap',
	license            => 'perl',
	requires           => {
		'File::Temp'        => 0,
		'Image::Magick'     => 0,
        'IO::All'           => '0.38',
        'IO::All::LWP'      => '0.14',
		'OpenOffice::OODoc' => 0,
	},
    build_requires     => {
        'Test::Distribution' => '1.29',
        'Devel::CheckOS'     => '1.42',
    },
	create_readme      => 1,
	scripts            => [ 'script/get_streetmap' ],
	create_makefile_pl => 'passthrough',
    add_to_cleanup       => [ '*.tar.gz', 'Build', '_build' ],
)->create_build_script;
