use Module::Build;
my $build = Module::Build->new(
    module_name => 'User::Simple',
    dist_abstract => 'Simple user sessions management',
    dist_author => 'Gunnar Wolf <gwolf@gwolf.org>',
    license => 'perl',

    requires => {Date::Calc => 0,
		 Digest::MD5 => 0,
		 DBI => 0},

    recommends => {},
    build_requires => {DBD::SQLite => 0,
		       Test::Pod => 0,
		       Module::Build => 0},

    create_makefile_pl => 'passthrough'
    );
$build->create_build_script;
