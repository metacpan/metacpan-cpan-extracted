# release instructions:
# bump version manually
# perl Build.PL
# Build manifest
# Build distcheck
# Build dist

use Module::Build;

Module::Build->new(
    module_name => 'Test::Regression',
    license => 'perl',
    requires => {
        'Test::More' => 0,
        'Test::Differences' => 0,
        'Text::Diff' => 0,
        'Algorithm::Diff' => 0,
	'FileHandle' => 0
    },
    build_requires => {
        'Test::MockObject' => 0,
	'DirHandle' => 0,
	'File::Spec' => 0
    },
    configure_requires => { 'Module::Build' => 0.42 },
    meta_merge => {
        resources=> {
            repository => 'http://github.com/periapt/test-regression',
        },
        keywords => ['Test','Regression'],
    },
    create_makefile_pl => 'traditional',
    dist_author => 'Nicholas Bamber <nicholas@periapt.co.uk>',
)->create_build_script;

