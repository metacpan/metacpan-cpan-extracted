use Module::Build;
my $build = Module::Build->new(
	module_name => 'Tie::Hash::Regex',
	license => 'perl',
	requires => {
		perl		      => '5.6.0',
		'Tie::Hash'	      => 0,
		'Attribute::Handlers' => 0,
	},
	build_requires => {
		'Test::More'	      => 0,
	},
	build_recommends => {
		'Test::Pod'           => 0,
		'Test::Pod::Coverage' => 0,
	},
        create_makefile_pl => 'traditional',
        meta_merge => {
                'meta-spec' => { version => 2 },
                resources => {
                        repository => {
                               type => 'git',
                               url  => 'git://github.com/davorg/tie-hash-regex.git',
                               web  => 'https://github.com/davorg/tie-hash-regex',
                        },
                        bugtracker => {
                               web  => 'https://github.com/davorg/tie-hash-regex/issues',
                        },
                },
        },
);

$build->create_build_script;
