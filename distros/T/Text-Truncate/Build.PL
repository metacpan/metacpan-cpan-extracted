use Module::Build;

my $build = Module::Build->new
    (
     module_name => 'Text::Truncate',
     license => 'unrestricted', # *Ahem* PUBLIC DOMAIN
     requires => {
       'perl'        => 5.004,
       'Carp'        => 0,
     },
     recommends => {
       'Test::Pod::Coverage' => 0,
       'Test::Pod'      => 1.00,
       'Test::Prereq'   => 0,
     },
     build_requires => {
       'Test::More'     => 0,
     },
     create_readme      => 0,
     create_makefile_pl => 'traditional',
     dist_author        => 'Robert Rothenberg <rrwo at cpan.org>',
     sign               => 0,
);

$build->create_build_script;
